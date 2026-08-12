--  Statically selected 256-bit composition through the native 128-bit backend.
package Flyology_SIMD.Wide.Native
  with Preelaborate
is
   function Make_Lane_Map (Selectors : Lane_Selectors_8x32) return Lane_Map_8x32 with Inline_Always;
   --  Build a reusable map from result lanes to source lanes.
   --  @param Selectors The selectors input.
   --  @return The operation result.
   function Select_Left_Lane (Lane : Lane_Index_8x32) return Two_Source_Lane_Selector_8x32 with Inline_Always;
   --  Construct a selector for one lane of the left input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Select_Right_Lane (Lane : Lane_Index_8x32) return Two_Source_Lane_Selector_8x32 with Inline_Always;
   --  Construct a selector for one lane of the right input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Make_Two_Source_Lane_Map (Selectors : Two_Source_Lane_Selectors_8x32) return Two_Source_Lane_Map_8x32 with Inline_Always;
   --  Build a reusable map from result lanes to lanes of two inputs.
   --  @param Selectors The selectors input.
   --  @return The operation result.
   function Zero return U8x32 with Inline_Always;
   --  Return a vector whose lanes are zero.
   --  @return The operation result.
   function Splat (Value : U8) return U8x32 with Inline_Always;
   --  Return a vector whose lanes all contain Value.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_U8x32) return U8x32 with Inline_Always;
   --  Construct a vector in logical lane order.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : U8x32) return Lane_Values_U8x32 with Inline_Always;
   --  Return all lanes in logical lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : U8x32; Lane : Lane_Index_8x32) return U8 with Inline_Always;
   --  Return one logical lane.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : U8x32; Lane : Lane_Index_8x32; With_Value : U8) return U8x32 with Inline_Always;
   --  Return a copy with one lane replaced.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Table_Lookup (Table, Indices : U8x32) return U8x32 with Inline_Always;
   --  Select each result byte from the corresponding unsigned index. Indexes from 0 through 31 select that table lane; larger indexes produce zero.
   --  @param Table The table input.
   --  @param Indices The indices input.
   --  @return The operation result.
   function Bit_Cast (Value : U8x32) return I8x32 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  @param Value The value input.
   --  @return The operation result.
   function Add_Wrap (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Apply Add_Wrap independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Apply Subtract_Wrap independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Apply Multiply_Wrap independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Apply Add_Saturate independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Apply Subtract_Saturate independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Apply Bitwise_And independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Apply Bitwise_Or independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Apply Bitwise_Xor independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Apply Min independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Apply Max independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : U8x32) return U8x32 with Inline_Always;
   --  Complement every bit in every lane.
   --  @param Value The value input.
   --  @return The operation result.
   function Shift_Left_Logical (Value : U8x32; Count : Natural) return U8x32 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Logical (Value : U8x32; Count : Natural) return U8x32 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Equal (Left, Right : U8x32) return Mask_8x32 with Inline_Always;
   --  Apply Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : U8x32) return Mask_8x32 with Inline_Always;
   --  Apply Less_Than independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : U8x32) return Mask_8x32 with Inline_Always;
   --  Apply Less_Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : U8x32) return Mask_8x32 with Inline_Always;
   --  Apply Greater_Than independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : U8x32) return Mask_8x32 with Inline_Always;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_8x32; If_True, If_False : U8x32) return U8x32 with Inline_Always;
   --  Select one input in each lane according to mask truth.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : U8x32; Mask : Mask_8x32) return U8x32 with Inline_Always;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : U8x32; Mask : Mask_8x32) return U8x32 with Inline_Always;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : U8x32) return U8 with Inline_Always;
   --  Apply Reduce_Add_Wrap in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min (Value : U8x32) return U8 with Inline_Always;
   --  Apply Reduce_Min in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max (Value : U8x32) return U8 with Inline_Always;
   --  Apply Reduce_Max in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : U8x32) return U8x32 with Inline_Always;
   --  Reverse logical lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : U8x32; Map : Lane_Map_8x32) return U8x32 with Inline_Always;
   --  Select each result lane through a reusable lane map.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : U8x32; Map : Two_Source_Lane_Map_8x32) return U8x32 with Inline_Always;
   --  Select each result lane from one lane of either input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Apply Interleave_Low with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Apply Interleave_High with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Apply Deinterleave_Even with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : U8x32) return U8x32 with Inline_Always;
   --  Apply Deinterleave_Odd with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : U8x32; Count : Natural) return U8x32 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : U8x32; Count : Natural) return U8x32 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Mask_From_Bit_Mask (Bits : Mask_Bits_8x32) return Mask_8x32 with Inline_Always;
   --  Construct lane truths from compact bits. Bit zero represents lane zero.
   --  @param Bits The bits input.
   --  @return The operation result.
   function To_Bit_Mask (Mask : Mask_8x32) return Mask_Bits_8x32 with Inline_Always;
   --  Return compact lane truths. Bit zero represents lane zero.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Mask_And (Left, Right : Mask_8x32) return Mask_8x32 with Inline_Always;
   --  Apply Mask_And to corresponding mask truths.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Or (Left, Right : Mask_8x32) return Mask_8x32 with Inline_Always;
   --  Apply Mask_Or to corresponding mask truths.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Xor (Left, Right : Mask_8x32) return Mask_8x32 with Inline_Always;
   --  Apply Mask_Xor to corresponding mask truths.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Not (Value : Mask_8x32) return Mask_8x32 with Inline_Always;
   --  Complement every mask truth.
   --  @param Value The value input.
   --  @return The operation result.
   function Test (Mask : Mask_8x32; Lane : Lane_Index_8x32) return Boolean with Inline_Always;
   --  Return one mask truth.
   --  @param Mask The mask input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Any_True (Mask : Mask_8x32) return Boolean with Inline_Always;
   --  Return the Any_True mask reduction.
   --  @param Mask The mask input.
   --  @return The operation result.
   function All_True (Mask : Mask_8x32) return Boolean with Inline_Always;
   --  Return the All_True mask reduction.
   --  @param Mask The mask input.
   --  @return The operation result.
   function None_True (Mask : Mask_8x32) return Boolean with Inline_Always;
   --  Return the None_True mask reduction.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Population_Count (Mask : Mask_8x32) return Lane_Count_8x32 with Inline_Always;
   --  Return the Population_Count mask position or count result.
   --  @param Mask The mask input.
   --  @return The operation result.
   function First_True (Mask : Mask_8x32) return Lane_Count_8x32 with Inline_Always;
   --  Return the First_True mask position or count result.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Last_True (Mask : Mask_8x32) return Lane_Count_8x32 with Inline_Always;
   --  Return the Last_True mask position or count result.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : Byte_Array; Start : Natural) return Boolean with Inline_Always;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : Byte_Array; Start : Natural) return U8x32 with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector without an alignment requirement.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out Byte_Array; Start : Natural; Value : U8x32) with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector without an alignment requirement.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : Byte_Array; Start : Natural) return U8x32 with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector from an address with any alignment.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out Byte_Array; Start : Natural; Value : U8x32) with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector to an address with any alignment.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : Byte_Array; Start : Natural) return U8x32 with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Load one complete vector from a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out Byte_Array; Start : Natural; Value : U8x32) with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Store one complete vector to a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : Byte_Array; Start : Natural; Count : Lane_Count_8x32) return U8x32 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out Byte_Array; Start : Natural; Count : Lane_Count_8x32; Value : U8x32) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Write exactly Count elements and leave all others unchanged.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.
   function Zero return I8x32 with Inline_Always;
   --  Return a vector whose lanes are zero.
   --  @return The operation result.
   function Splat (Value : I8) return I8x32 with Inline_Always;
   --  Return a vector whose lanes all contain Value.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_I8x32) return I8x32 with Inline_Always;
   --  Construct a vector in logical lane order.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : I8x32) return Lane_Values_I8x32 with Inline_Always;
   --  Return all lanes in logical lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : I8x32; Lane : Lane_Index_8x32) return I8 with Inline_Always;
   --  Return one logical lane.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : I8x32; Lane : Lane_Index_8x32; With_Value : I8) return I8x32 with Inline_Always;
   --  Return a copy with one lane replaced.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Bit_Cast (Value : I8x32) return U8x32 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  @param Value The value input.
   --  @return The operation result.
   function Add_Wrap (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Apply Add_Wrap independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Apply Subtract_Wrap independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Apply Multiply_Wrap independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Apply Add_Saturate independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Apply Subtract_Saturate independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Apply Bitwise_And independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Apply Bitwise_Or independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Apply Bitwise_Xor independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Apply Min independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Apply Max independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : I8x32) return I8x32 with Inline_Always;
   --  Complement every bit in every lane.
   --  @param Value The value input.
   --  @return The operation result.
   function Shift_Left_Logical (Value : I8x32; Count : Natural) return I8x32 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Logical (Value : I8x32; Count : Natural) return I8x32 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Arithmetic (Value : I8x32; Count : Natural) return I8x32 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Equal (Left, Right : I8x32) return Mask_8x32 with Inline_Always;
   --  Apply Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : I8x32) return Mask_8x32 with Inline_Always;
   --  Apply Less_Than independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : I8x32) return Mask_8x32 with Inline_Always;
   --  Apply Less_Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : I8x32) return Mask_8x32 with Inline_Always;
   --  Apply Greater_Than independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : I8x32) return Mask_8x32 with Inline_Always;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_8x32; If_True, If_False : I8x32) return I8x32 with Inline_Always;
   --  Select one input in each lane according to mask truth.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : I8x32; Mask : Mask_8x32) return I8x32 with Inline_Always;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : I8x32; Mask : Mask_8x32) return I8x32 with Inline_Always;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : I8x32) return I8 with Inline_Always;
   --  Apply Reduce_Add_Wrap in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min (Value : I8x32) return I8 with Inline_Always;
   --  Apply Reduce_Min in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max (Value : I8x32) return I8 with Inline_Always;
   --  Apply Reduce_Max in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : I8x32) return I8x32 with Inline_Always;
   --  Reverse logical lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : I8x32; Map : Lane_Map_8x32) return I8x32 with Inline_Always;
   --  Select each result lane through a reusable lane map.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : I8x32; Map : Two_Source_Lane_Map_8x32) return I8x32 with Inline_Always;
   --  Select each result lane from one lane of either input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Apply Interleave_Low with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Apply Interleave_High with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Apply Deinterleave_Even with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : I8x32) return I8x32 with Inline_Always;
   --  Apply Deinterleave_Odd with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : I8x32; Count : Natural) return I8x32 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : I8x32; Count : Natural) return I8x32 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : I8_Array; Start : Natural) return Boolean with Inline_Always;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : I8_Array; Start : Natural) return I8x32 with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector without an alignment requirement.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out I8_Array; Start : Natural; Value : I8x32) with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector without an alignment requirement.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : I8_Array; Start : Natural) return I8x32 with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector from an address with any alignment.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out I8_Array; Start : Natural; Value : I8x32) with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector to an address with any alignment.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : I8_Array; Start : Natural) return I8x32 with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Load one complete vector from a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out I8_Array; Start : Natural; Value : I8x32) with Pre => Start in Data'Range and then 31 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Store one complete vector to a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : I8_Array; Start : Natural; Count : Lane_Count_8x32) return I8x32 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out I8_Array; Start : Natural; Count : Lane_Count_8x32; Value : I8x32) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Write exactly Count elements and leave all others unchanged.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.
   function Make_Lane_Map (Selectors : Lane_Selectors_16x16) return Lane_Map_16x16 with Inline_Always;
   --  Build a reusable map from result lanes to source lanes.
   --  @param Selectors The selectors input.
   --  @return The operation result.
   function Select_Left_Lane (Lane : Lane_Index_16x16) return Two_Source_Lane_Selector_16x16 with Inline_Always;
   --  Construct a selector for one lane of the left input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Select_Right_Lane (Lane : Lane_Index_16x16) return Two_Source_Lane_Selector_16x16 with Inline_Always;
   --  Construct a selector for one lane of the right input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Make_Two_Source_Lane_Map (Selectors : Two_Source_Lane_Selectors_16x16) return Two_Source_Lane_Map_16x16 with Inline_Always;
   --  Build a reusable map from result lanes to lanes of two inputs.
   --  @param Selectors The selectors input.
   --  @return The operation result.
   function Zero return U16x16 with Inline_Always;
   --  Return a vector whose lanes are zero.
   --  @return The operation result.
   function Splat (Value : U16) return U16x16 with Inline_Always;
   --  Return a vector whose lanes all contain Value.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_U16x16) return U16x16 with Inline_Always;
   --  Construct a vector in logical lane order.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : U16x16) return Lane_Values_U16x16 with Inline_Always;
   --  Return all lanes in logical lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : U16x16; Lane : Lane_Index_16x16) return U16 with Inline_Always;
   --  Return one logical lane.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : U16x16; Lane : Lane_Index_16x16; With_Value : U16) return U16x16 with Inline_Always;
   --  Return a copy with one lane replaced.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Bit_Cast (Value : U16x16) return I16x16 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  @param Value The value input.
   --  @return The operation result.
   function Add_Wrap (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Apply Add_Wrap independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Apply Subtract_Wrap independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Apply Multiply_Wrap independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Apply Add_Saturate independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Apply Subtract_Saturate independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Apply Bitwise_And independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Apply Bitwise_Or independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Apply Bitwise_Xor independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Apply Min independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Apply Max independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : U16x16) return U16x16 with Inline_Always;
   --  Complement every bit in every lane.
   --  @param Value The value input.
   --  @return The operation result.
   function Shift_Left_Logical (Value : U16x16; Count : Natural) return U16x16 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Logical (Value : U16x16; Count : Natural) return U16x16 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Equal (Left, Right : U16x16) return Mask_16x16 with Inline_Always;
   --  Apply Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : U16x16) return Mask_16x16 with Inline_Always;
   --  Apply Less_Than independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : U16x16) return Mask_16x16 with Inline_Always;
   --  Apply Less_Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : U16x16) return Mask_16x16 with Inline_Always;
   --  Apply Greater_Than independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : U16x16) return Mask_16x16 with Inline_Always;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_16x16; If_True, If_False : U16x16) return U16x16 with Inline_Always;
   --  Select one input in each lane according to mask truth.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : U16x16; Mask : Mask_16x16) return U16x16 with Inline_Always;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : U16x16; Mask : Mask_16x16) return U16x16 with Inline_Always;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : U16x16) return U16 with Inline_Always;
   --  Apply Reduce_Add_Wrap in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min (Value : U16x16) return U16 with Inline_Always;
   --  Apply Reduce_Min in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max (Value : U16x16) return U16 with Inline_Always;
   --  Apply Reduce_Max in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : U16x16) return U16x16 with Inline_Always;
   --  Reverse logical lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : U16x16; Map : Lane_Map_16x16) return U16x16 with Inline_Always;
   --  Select each result lane through a reusable lane map.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : U16x16; Map : Two_Source_Lane_Map_16x16) return U16x16 with Inline_Always;
   --  Select each result lane from one lane of either input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Apply Interleave_Low with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Apply Interleave_High with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Apply Deinterleave_Even with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : U16x16) return U16x16 with Inline_Always;
   --  Apply Deinterleave_Odd with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : U16x16; Count : Natural) return U16x16 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : U16x16; Count : Natural) return U16x16 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Mask_From_Bit_Mask (Bits : Mask_Bits_16x16) return Mask_16x16 with Inline_Always;
   --  Construct lane truths from compact bits. Bit zero represents lane zero.
   --  @param Bits The bits input.
   --  @return The operation result.
   function To_Bit_Mask (Mask : Mask_16x16) return Mask_Bits_16x16 with Inline_Always;
   --  Return compact lane truths. Bit zero represents lane zero.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Mask_And (Left, Right : Mask_16x16) return Mask_16x16 with Inline_Always;
   --  Apply Mask_And to corresponding mask truths.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Or (Left, Right : Mask_16x16) return Mask_16x16 with Inline_Always;
   --  Apply Mask_Or to corresponding mask truths.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Xor (Left, Right : Mask_16x16) return Mask_16x16 with Inline_Always;
   --  Apply Mask_Xor to corresponding mask truths.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Not (Value : Mask_16x16) return Mask_16x16 with Inline_Always;
   --  Complement every mask truth.
   --  @param Value The value input.
   --  @return The operation result.
   function Test (Mask : Mask_16x16; Lane : Lane_Index_16x16) return Boolean with Inline_Always;
   --  Return one mask truth.
   --  @param Mask The mask input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Any_True (Mask : Mask_16x16) return Boolean with Inline_Always;
   --  Return the Any_True mask reduction.
   --  @param Mask The mask input.
   --  @return The operation result.
   function All_True (Mask : Mask_16x16) return Boolean with Inline_Always;
   --  Return the All_True mask reduction.
   --  @param Mask The mask input.
   --  @return The operation result.
   function None_True (Mask : Mask_16x16) return Boolean with Inline_Always;
   --  Return the None_True mask reduction.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Population_Count (Mask : Mask_16x16) return Lane_Count_16x16 with Inline_Always;
   --  Return the Population_Count mask position or count result.
   --  @param Mask The mask input.
   --  @return The operation result.
   function First_True (Mask : Mask_16x16) return Lane_Count_16x16 with Inline_Always;
   --  Return the First_True mask position or count result.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Last_True (Mask : Mask_16x16) return Lane_Count_16x16 with Inline_Always;
   --  Return the Last_True mask position or count result.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : U16_Array; Start : Natural) return Boolean with Inline_Always;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : U16_Array; Start : Natural) return U16x16 with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector without an alignment requirement.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out U16_Array; Start : Natural; Value : U16x16) with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector without an alignment requirement.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : U16_Array; Start : Natural) return U16x16 with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector from an address with any alignment.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out U16_Array; Start : Natural; Value : U16x16) with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector to an address with any alignment.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : U16_Array; Start : Natural) return U16x16 with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Load one complete vector from a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out U16_Array; Start : Natural; Value : U16x16) with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Store one complete vector to a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : U16_Array; Start : Natural; Count : Lane_Count_16x16) return U16x16 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out U16_Array; Start : Natural; Count : Lane_Count_16x16; Value : U16x16) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Write exactly Count elements and leave all others unchanged.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.
   function Zero return I16x16 with Inline_Always;
   --  Return a vector whose lanes are zero.
   --  @return The operation result.
   function Splat (Value : I16) return I16x16 with Inline_Always;
   --  Return a vector whose lanes all contain Value.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_I16x16) return I16x16 with Inline_Always;
   --  Construct a vector in logical lane order.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : I16x16) return Lane_Values_I16x16 with Inline_Always;
   --  Return all lanes in logical lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : I16x16; Lane : Lane_Index_16x16) return I16 with Inline_Always;
   --  Return one logical lane.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : I16x16; Lane : Lane_Index_16x16; With_Value : I16) return I16x16 with Inline_Always;
   --  Return a copy with one lane replaced.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Bit_Cast (Value : I16x16) return U16x16 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  @param Value The value input.
   --  @return The operation result.
   function Add_Wrap (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Apply Add_Wrap independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Apply Subtract_Wrap independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Apply Multiply_Wrap independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Apply Add_Saturate independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Apply Subtract_Saturate independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Apply Bitwise_And independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Apply Bitwise_Or independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Apply Bitwise_Xor independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Apply Min independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Apply Max independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : I16x16) return I16x16 with Inline_Always;
   --  Complement every bit in every lane.
   --  @param Value The value input.
   --  @return The operation result.
   function Shift_Left_Logical (Value : I16x16; Count : Natural) return I16x16 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Logical (Value : I16x16; Count : Natural) return I16x16 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Arithmetic (Value : I16x16; Count : Natural) return I16x16 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Equal (Left, Right : I16x16) return Mask_16x16 with Inline_Always;
   --  Apply Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : I16x16) return Mask_16x16 with Inline_Always;
   --  Apply Less_Than independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : I16x16) return Mask_16x16 with Inline_Always;
   --  Apply Less_Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : I16x16) return Mask_16x16 with Inline_Always;
   --  Apply Greater_Than independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : I16x16) return Mask_16x16 with Inline_Always;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_16x16; If_True, If_False : I16x16) return I16x16 with Inline_Always;
   --  Select one input in each lane according to mask truth.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : I16x16; Mask : Mask_16x16) return I16x16 with Inline_Always;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : I16x16; Mask : Mask_16x16) return I16x16 with Inline_Always;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : I16x16) return I16 with Inline_Always;
   --  Apply Reduce_Add_Wrap in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min (Value : I16x16) return I16 with Inline_Always;
   --  Apply Reduce_Min in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max (Value : I16x16) return I16 with Inline_Always;
   --  Apply Reduce_Max in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : I16x16) return I16x16 with Inline_Always;
   --  Reverse logical lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : I16x16; Map : Lane_Map_16x16) return I16x16 with Inline_Always;
   --  Select each result lane through a reusable lane map.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : I16x16; Map : Two_Source_Lane_Map_16x16) return I16x16 with Inline_Always;
   --  Select each result lane from one lane of either input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Apply Interleave_Low with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Apply Interleave_High with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Apply Deinterleave_Even with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : I16x16) return I16x16 with Inline_Always;
   --  Apply Deinterleave_Odd with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : I16x16; Count : Natural) return I16x16 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : I16x16; Count : Natural) return I16x16 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : I16_Array; Start : Natural) return Boolean with Inline_Always;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : I16_Array; Start : Natural) return I16x16 with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector without an alignment requirement.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out I16_Array; Start : Natural; Value : I16x16) with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector without an alignment requirement.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : I16_Array; Start : Natural) return I16x16 with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector from an address with any alignment.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out I16_Array; Start : Natural; Value : I16x16) with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector to an address with any alignment.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : I16_Array; Start : Natural) return I16x16 with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Load one complete vector from a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out I16_Array; Start : Natural; Value : I16x16) with Pre => Start in Data'Range and then 15 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Store one complete vector to a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : I16_Array; Start : Natural; Count : Lane_Count_16x16) return I16x16 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out I16_Array; Start : Natural; Count : Lane_Count_16x16; Value : I16x16) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Write exactly Count elements and leave all others unchanged.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.
   function Make_Lane_Map (Selectors : Lane_Selectors_32x8) return Lane_Map_32x8 with Inline_Always;
   --  Build a reusable map from result lanes to source lanes.
   --  @param Selectors The selectors input.
   --  @return The operation result.
   function Select_Left_Lane (Lane : Lane_Index_32x8) return Two_Source_Lane_Selector_32x8 with Inline_Always;
   --  Construct a selector for one lane of the left input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Select_Right_Lane (Lane : Lane_Index_32x8) return Two_Source_Lane_Selector_32x8 with Inline_Always;
   --  Construct a selector for one lane of the right input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Make_Two_Source_Lane_Map (Selectors : Two_Source_Lane_Selectors_32x8) return Two_Source_Lane_Map_32x8 with Inline_Always;
   --  Build a reusable map from result lanes to lanes of two inputs.
   --  @param Selectors The selectors input.
   --  @return The operation result.
   function Zero return U32x8 with Inline_Always;
   --  Return a vector whose lanes are zero.
   --  @return The operation result.
   function Splat (Value : U32) return U32x8 with Inline_Always;
   --  Return a vector whose lanes all contain Value.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_U32x8) return U32x8 with Inline_Always;
   --  Construct a vector in logical lane order.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : U32x8) return Lane_Values_U32x8 with Inline_Always;
   --  Return all lanes in logical lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : U32x8; Lane : Lane_Index_32x8) return U32 with Inline_Always;
   --  Return one logical lane.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : U32x8; Lane : Lane_Index_32x8; With_Value : U32) return U32x8 with Inline_Always;
   --  Return a copy with one lane replaced.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Bit_Cast (Value : U32x8) return I32x8 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  @param Value The value input.
   --  @return The operation result.
   function Bit_Cast (Value : U32x8) return F32x8 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  @param Value The value input.
   --  @return The operation result.
   function Add_Wrap (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Apply Add_Wrap independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Apply Subtract_Wrap independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Apply Multiply_Wrap independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Apply Add_Saturate independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Apply Subtract_Saturate independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Apply Bitwise_And independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Apply Bitwise_Or independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Apply Bitwise_Xor independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Apply Min independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Apply Max independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : U32x8) return U32x8 with Inline_Always;
   --  Complement every bit in every lane.
   --  @param Value The value input.
   --  @return The operation result.
   function Shift_Left_Logical (Value : U32x8; Count : Natural) return U32x8 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Logical (Value : U32x8; Count : Natural) return U32x8 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Equal (Left, Right : U32x8) return Mask_32x8 with Inline_Always;
   --  Apply Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : U32x8) return Mask_32x8 with Inline_Always;
   --  Apply Less_Than independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : U32x8) return Mask_32x8 with Inline_Always;
   --  Apply Less_Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : U32x8) return Mask_32x8 with Inline_Always;
   --  Apply Greater_Than independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : U32x8) return Mask_32x8 with Inline_Always;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_32x8; If_True, If_False : U32x8) return U32x8 with Inline_Always;
   --  Select one input in each lane according to mask truth.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : U32x8; Mask : Mask_32x8) return U32x8 with Inline_Always;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : U32x8; Mask : Mask_32x8) return U32x8 with Inline_Always;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : U32x8) return U32 with Inline_Always;
   --  Apply Reduce_Add_Wrap in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min (Value : U32x8) return U32 with Inline_Always;
   --  Apply Reduce_Min in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max (Value : U32x8) return U32 with Inline_Always;
   --  Apply Reduce_Max in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : U32x8) return U32x8 with Inline_Always;
   --  Reverse logical lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : U32x8; Map : Lane_Map_32x8) return U32x8 with Inline_Always;
   --  Select each result lane through a reusable lane map.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : U32x8; Map : Two_Source_Lane_Map_32x8) return U32x8 with Inline_Always;
   --  Select each result lane from one lane of either input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Apply Interleave_Low with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Apply Interleave_High with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Apply Deinterleave_Even with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : U32x8) return U32x8 with Inline_Always;
   --  Apply Deinterleave_Odd with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : U32x8; Count : Natural) return U32x8 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : U32x8; Count : Natural) return U32x8 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Mask_From_Bit_Mask (Bits : Mask_Bits_32x8) return Mask_32x8 with Inline_Always;
   --  Construct lane truths from compact bits. Bit zero represents lane zero.
   --  @param Bits The bits input.
   --  @return The operation result.
   function To_Bit_Mask (Mask : Mask_32x8) return Mask_Bits_32x8 with Inline_Always;
   --  Return compact lane truths. Bit zero represents lane zero.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Mask_And (Left, Right : Mask_32x8) return Mask_32x8 with Inline_Always;
   --  Apply Mask_And to corresponding mask truths.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Or (Left, Right : Mask_32x8) return Mask_32x8 with Inline_Always;
   --  Apply Mask_Or to corresponding mask truths.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Xor (Left, Right : Mask_32x8) return Mask_32x8 with Inline_Always;
   --  Apply Mask_Xor to corresponding mask truths.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Not (Value : Mask_32x8) return Mask_32x8 with Inline_Always;
   --  Complement every mask truth.
   --  @param Value The value input.
   --  @return The operation result.
   function Test (Mask : Mask_32x8; Lane : Lane_Index_32x8) return Boolean with Inline_Always;
   --  Return one mask truth.
   --  @param Mask The mask input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Any_True (Mask : Mask_32x8) return Boolean with Inline_Always;
   --  Return the Any_True mask reduction.
   --  @param Mask The mask input.
   --  @return The operation result.
   function All_True (Mask : Mask_32x8) return Boolean with Inline_Always;
   --  Return the All_True mask reduction.
   --  @param Mask The mask input.
   --  @return The operation result.
   function None_True (Mask : Mask_32x8) return Boolean with Inline_Always;
   --  Return the None_True mask reduction.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Population_Count (Mask : Mask_32x8) return Lane_Count_32x8 with Inline_Always;
   --  Return the Population_Count mask position or count result.
   --  @param Mask The mask input.
   --  @return The operation result.
   function First_True (Mask : Mask_32x8) return Lane_Count_32x8 with Inline_Always;
   --  Return the First_True mask position or count result.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Last_True (Mask : Mask_32x8) return Lane_Count_32x8 with Inline_Always;
   --  Return the Last_True mask position or count result.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : U32_Array; Start : Natural) return Boolean with Inline_Always;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : U32_Array; Start : Natural) return U32x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector without an alignment requirement.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out U32_Array; Start : Natural; Value : U32x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector without an alignment requirement.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : U32_Array; Start : Natural) return U32x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector from an address with any alignment.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out U32_Array; Start : Natural; Value : U32x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector to an address with any alignment.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : U32_Array; Start : Natural) return U32x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Load one complete vector from a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out U32_Array; Start : Natural; Value : U32x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Store one complete vector to a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : U32_Array; Start : Natural; Count : Lane_Count_32x8) return U32x8 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out U32_Array; Start : Natural; Count : Lane_Count_32x8; Value : U32x8) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Write exactly Count elements and leave all others unchanged.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.
   function Zero return I32x8 with Inline_Always;
   --  Return a vector whose lanes are zero.
   --  @return The operation result.
   function Splat (Value : I32) return I32x8 with Inline_Always;
   --  Return a vector whose lanes all contain Value.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_I32x8) return I32x8 with Inline_Always;
   --  Construct a vector in logical lane order.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : I32x8) return Lane_Values_I32x8 with Inline_Always;
   --  Return all lanes in logical lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : I32x8; Lane : Lane_Index_32x8) return I32 with Inline_Always;
   --  Return one logical lane.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : I32x8; Lane : Lane_Index_32x8; With_Value : I32) return I32x8 with Inline_Always;
   --  Return a copy with one lane replaced.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Bit_Cast (Value : I32x8) return U32x8 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  @param Value The value input.
   --  @return The operation result.
   function Bit_Cast (Value : I32x8) return F32x8 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  @param Value The value input.
   --  @return The operation result.
   function Add_Wrap (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Apply Add_Wrap independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Apply Subtract_Wrap independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Apply Multiply_Wrap independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Apply Add_Saturate independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Apply Subtract_Saturate independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Apply Bitwise_And independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Apply Bitwise_Or independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Apply Bitwise_Xor independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Apply Min independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Apply Max independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : I32x8) return I32x8 with Inline_Always;
   --  Complement every bit in every lane.
   --  @param Value The value input.
   --  @return The operation result.
   function Shift_Left_Logical (Value : I32x8; Count : Natural) return I32x8 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Logical (Value : I32x8; Count : Natural) return I32x8 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Arithmetic (Value : I32x8; Count : Natural) return I32x8 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Equal (Left, Right : I32x8) return Mask_32x8 with Inline_Always;
   --  Apply Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : I32x8) return Mask_32x8 with Inline_Always;
   --  Apply Less_Than independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : I32x8) return Mask_32x8 with Inline_Always;
   --  Apply Less_Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : I32x8) return Mask_32x8 with Inline_Always;
   --  Apply Greater_Than independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : I32x8) return Mask_32x8 with Inline_Always;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_32x8; If_True, If_False : I32x8) return I32x8 with Inline_Always;
   --  Select one input in each lane according to mask truth.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : I32x8; Mask : Mask_32x8) return I32x8 with Inline_Always;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : I32x8; Mask : Mask_32x8) return I32x8 with Inline_Always;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : I32x8) return I32 with Inline_Always;
   --  Apply Reduce_Add_Wrap in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min (Value : I32x8) return I32 with Inline_Always;
   --  Apply Reduce_Min in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max (Value : I32x8) return I32 with Inline_Always;
   --  Apply Reduce_Max in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : I32x8) return I32x8 with Inline_Always;
   --  Reverse logical lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : I32x8; Map : Lane_Map_32x8) return I32x8 with Inline_Always;
   --  Select each result lane through a reusable lane map.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : I32x8; Map : Two_Source_Lane_Map_32x8) return I32x8 with Inline_Always;
   --  Select each result lane from one lane of either input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Apply Interleave_Low with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Apply Interleave_High with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Apply Deinterleave_Even with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : I32x8) return I32x8 with Inline_Always;
   --  Apply Deinterleave_Odd with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : I32x8; Count : Natural) return I32x8 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : I32x8; Count : Natural) return I32x8 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : I32_Array; Start : Natural) return Boolean with Inline_Always;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : I32_Array; Start : Natural) return I32x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector without an alignment requirement.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out I32_Array; Start : Natural; Value : I32x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector without an alignment requirement.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : I32_Array; Start : Natural) return I32x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector from an address with any alignment.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out I32_Array; Start : Natural; Value : I32x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector to an address with any alignment.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : I32_Array; Start : Natural) return I32x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Load one complete vector from a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out I32_Array; Start : Natural; Value : I32x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Store one complete vector to a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : I32_Array; Start : Natural; Count : Lane_Count_32x8) return I32x8 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out I32_Array; Start : Natural; Count : Lane_Count_32x8; Value : I32x8) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Write exactly Count elements and leave all others unchanged.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.
   function Make_Lane_Map (Selectors : Lane_Selectors_64x4) return Lane_Map_64x4 with Inline_Always;
   --  Build a reusable map from result lanes to source lanes.
   --  @param Selectors The selectors input.
   --  @return The operation result.
   function Select_Left_Lane (Lane : Lane_Index_64x4) return Two_Source_Lane_Selector_64x4 with Inline_Always;
   --  Construct a selector for one lane of the left input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Select_Right_Lane (Lane : Lane_Index_64x4) return Two_Source_Lane_Selector_64x4 with Inline_Always;
   --  Construct a selector for one lane of the right input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Make_Two_Source_Lane_Map (Selectors : Two_Source_Lane_Selectors_64x4) return Two_Source_Lane_Map_64x4 with Inline_Always;
   --  Build a reusable map from result lanes to lanes of two inputs.
   --  @param Selectors The selectors input.
   --  @return The operation result.
   function Zero return U64x4 with Inline_Always;
   --  Return a vector whose lanes are zero.
   --  @return The operation result.
   function Splat (Value : U64) return U64x4 with Inline_Always;
   --  Return a vector whose lanes all contain Value.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_U64x4) return U64x4 with Inline_Always;
   --  Construct a vector in logical lane order.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : U64x4) return Lane_Values_U64x4 with Inline_Always;
   --  Return all lanes in logical lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : U64x4; Lane : Lane_Index_64x4) return U64 with Inline_Always;
   --  Return one logical lane.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : U64x4; Lane : Lane_Index_64x4; With_Value : U64) return U64x4 with Inline_Always;
   --  Return a copy with one lane replaced.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Bit_Cast (Value : U64x4) return I64x4 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  @param Value The value input.
   --  @return The operation result.
   function Bit_Cast (Value : U64x4) return F64x4 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  @param Value The value input.
   --  @return The operation result.
   function Add_Wrap (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Apply Add_Wrap independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Apply Subtract_Wrap independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Apply Multiply_Wrap independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Apply Add_Saturate independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Apply Subtract_Saturate independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Apply Bitwise_And independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Apply Bitwise_Or independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Apply Bitwise_Xor independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Apply Min independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Apply Max independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : U64x4) return U64x4 with Inline_Always;
   --  Complement every bit in every lane.
   --  @param Value The value input.
   --  @return The operation result.
   function Shift_Left_Logical (Value : U64x4; Count : Natural) return U64x4 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Logical (Value : U64x4; Count : Natural) return U64x4 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Equal (Left, Right : U64x4) return Mask_64x4 with Inline_Always;
   --  Apply Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : U64x4) return Mask_64x4 with Inline_Always;
   --  Apply Less_Than independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : U64x4) return Mask_64x4 with Inline_Always;
   --  Apply Less_Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : U64x4) return Mask_64x4 with Inline_Always;
   --  Apply Greater_Than independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : U64x4) return Mask_64x4 with Inline_Always;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_64x4; If_True, If_False : U64x4) return U64x4 with Inline_Always;
   --  Select one input in each lane according to mask truth.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : U64x4; Mask : Mask_64x4) return U64x4 with Inline_Always;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : U64x4; Mask : Mask_64x4) return U64x4 with Inline_Always;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : U64x4) return U64 with Inline_Always;
   --  Apply Reduce_Add_Wrap in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min (Value : U64x4) return U64 with Inline_Always;
   --  Apply Reduce_Min in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max (Value : U64x4) return U64 with Inline_Always;
   --  Apply Reduce_Max in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : U64x4) return U64x4 with Inline_Always;
   --  Reverse logical lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : U64x4; Map : Lane_Map_64x4) return U64x4 with Inline_Always;
   --  Select each result lane through a reusable lane map.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : U64x4; Map : Two_Source_Lane_Map_64x4) return U64x4 with Inline_Always;
   --  Select each result lane from one lane of either input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Apply Interleave_Low with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Apply Interleave_High with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Apply Deinterleave_Even with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : U64x4) return U64x4 with Inline_Always;
   --  Apply Deinterleave_Odd with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : U64x4; Count : Natural) return U64x4 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : U64x4; Count : Natural) return U64x4 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Mask_From_Bit_Mask (Bits : Mask_Bits_64x4) return Mask_64x4 with Inline_Always;
   --  Construct lane truths from compact bits. Bit zero represents lane zero.
   --  @param Bits The bits input.
   --  @return The operation result.
   function To_Bit_Mask (Mask : Mask_64x4) return Mask_Bits_64x4 with Inline_Always;
   --  Return compact lane truths. Bit zero represents lane zero.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Mask_And (Left, Right : Mask_64x4) return Mask_64x4 with Inline_Always;
   --  Apply Mask_And to corresponding mask truths.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Or (Left, Right : Mask_64x4) return Mask_64x4 with Inline_Always;
   --  Apply Mask_Or to corresponding mask truths.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Xor (Left, Right : Mask_64x4) return Mask_64x4 with Inline_Always;
   --  Apply Mask_Xor to corresponding mask truths.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Mask_Not (Value : Mask_64x4) return Mask_64x4 with Inline_Always;
   --  Complement every mask truth.
   --  @param Value The value input.
   --  @return The operation result.
   function Test (Mask : Mask_64x4; Lane : Lane_Index_64x4) return Boolean with Inline_Always;
   --  Return one mask truth.
   --  @param Mask The mask input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Any_True (Mask : Mask_64x4) return Boolean with Inline_Always;
   --  Return the Any_True mask reduction.
   --  @param Mask The mask input.
   --  @return The operation result.
   function All_True (Mask : Mask_64x4) return Boolean with Inline_Always;
   --  Return the All_True mask reduction.
   --  @param Mask The mask input.
   --  @return The operation result.
   function None_True (Mask : Mask_64x4) return Boolean with Inline_Always;
   --  Return the None_True mask reduction.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Population_Count (Mask : Mask_64x4) return Lane_Count_64x4 with Inline_Always;
   --  Return the Population_Count mask position or count result.
   --  @param Mask The mask input.
   --  @return The operation result.
   function First_True (Mask : Mask_64x4) return Lane_Count_64x4 with Inline_Always;
   --  Return the First_True mask position or count result.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Last_True (Mask : Mask_64x4) return Lane_Count_64x4 with Inline_Always;
   --  Return the Last_True mask position or count result.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : U64_Array; Start : Natural) return Boolean with Inline_Always;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : U64_Array; Start : Natural) return U64x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector without an alignment requirement.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out U64_Array; Start : Natural; Value : U64x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector without an alignment requirement.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : U64_Array; Start : Natural) return U64x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector from an address with any alignment.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out U64_Array; Start : Natural; Value : U64x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector to an address with any alignment.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : U64_Array; Start : Natural) return U64x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Load one complete vector from a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out U64_Array; Start : Natural; Value : U64x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Store one complete vector to a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : U64_Array; Start : Natural; Count : Lane_Count_64x4) return U64x4 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out U64_Array; Start : Natural; Count : Lane_Count_64x4; Value : U64x4) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Write exactly Count elements and leave all others unchanged.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.
   function Zero return I64x4 with Inline_Always;
   --  Return a vector whose lanes are zero.
   --  @return The operation result.
   function Splat (Value : I64) return I64x4 with Inline_Always;
   --  Return a vector whose lanes all contain Value.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_I64x4) return I64x4 with Inline_Always;
   --  Construct a vector in logical lane order.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : I64x4) return Lane_Values_I64x4 with Inline_Always;
   --  Return all lanes in logical lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : I64x4; Lane : Lane_Index_64x4) return I64 with Inline_Always;
   --  Return one logical lane.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : I64x4; Lane : Lane_Index_64x4; With_Value : I64) return I64x4 with Inline_Always;
   --  Return a copy with one lane replaced.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Bit_Cast (Value : I64x4) return U64x4 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  @param Value The value input.
   --  @return The operation result.
   function Bit_Cast (Value : I64x4) return F64x4 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  @param Value The value input.
   --  @return The operation result.
   function Add_Wrap (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Apply Add_Wrap independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Wrap (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Apply Subtract_Wrap independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply_Wrap (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Apply Multiply_Wrap independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Add_Saturate (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Apply Add_Saturate independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract_Saturate (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Apply Subtract_Saturate independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_And (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Apply Bitwise_And independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Or (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Apply Bitwise_Or independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Xor (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Apply Bitwise_Xor independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Apply Min independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Apply Max independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Bitwise_Not (Value : I64x4) return I64x4 with Inline_Always;
   --  Complement every bit in every lane.
   --  @param Value The value input.
   --  @return The operation result.
   function Shift_Left_Logical (Value : I64x4; Count : Natural) return I64x4 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Logical (Value : I64x4; Count : Natural) return I64x4 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Shift_Right_Arithmetic (Value : I64x4; Count : Natural) return I64x4 with Inline_Always;
   --  Shift every lane with the documented oversized-count result.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Equal (Left, Right : I64x4) return Mask_64x4 with Inline_Always;
   --  Apply Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : I64x4) return Mask_64x4 with Inline_Always;
   --  Apply Less_Than independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : I64x4) return Mask_64x4 with Inline_Always;
   --  Apply Less_Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : I64x4) return Mask_64x4 with Inline_Always;
   --  Apply Greater_Than independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : I64x4) return Mask_64x4 with Inline_Always;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_64x4; If_True, If_False : I64x4) return I64x4 with Inline_Always;
   --  Select one input in each lane according to mask truth.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : I64x4; Mask : Mask_64x4) return I64x4 with Inline_Always;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : I64x4; Mask : Mask_64x4) return I64x4 with Inline_Always;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add_Wrap (Value : I64x4) return I64 with Inline_Always;
   --  Apply Reduce_Add_Wrap in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min (Value : I64x4) return I64 with Inline_Always;
   --  Apply Reduce_Min in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max (Value : I64x4) return I64 with Inline_Always;
   --  Apply Reduce_Max in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : I64x4) return I64x4 with Inline_Always;
   --  Reverse logical lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : I64x4; Map : Lane_Map_64x4) return I64x4 with Inline_Always;
   --  Select each result lane through a reusable lane map.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : I64x4; Map : Two_Source_Lane_Map_64x4) return I64x4 with Inline_Always;
   --  Select each result lane from one lane of either input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Apply Interleave_Low with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Apply Interleave_High with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Apply Deinterleave_Even with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : I64x4) return I64x4 with Inline_Always;
   --  Apply Deinterleave_Odd with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : I64x4; Count : Natural) return I64x4 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : I64x4; Count : Natural) return I64x4 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : I64_Array; Start : Natural) return Boolean with Inline_Always;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : I64_Array; Start : Natural) return I64x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector without an alignment requirement.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out I64_Array; Start : Natural; Value : I64x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector without an alignment requirement.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : I64_Array; Start : Natural) return I64x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector from an address with any alignment.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out I64_Array; Start : Natural; Value : I64x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector to an address with any alignment.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : I64_Array; Start : Natural) return I64x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Load one complete vector from a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out I64_Array; Start : Natural; Value : I64x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Store one complete vector to a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : I64_Array; Start : Natural; Count : Lane_Count_64x4) return I64x4 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out I64_Array; Start : Natural; Count : Lane_Count_64x4; Value : I64x4) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Write exactly Count elements and leave all others unchanged.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.
   function Zero return F32x8 with Inline_Always;
   --  Return a vector whose lanes are zero.
   --  @return The operation result.
   function Splat (Value : F32) return F32x8 with Inline_Always;
   --  Return a vector whose lanes all contain Value.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_F32x8) return F32x8 with Inline_Always;
   --  Construct a vector in logical lane order.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : F32x8) return Lane_Values_F32x8 with Inline_Always;
   --  Return all lanes in logical lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : F32x8; Lane : Lane_Index_32x8) return F32 with Inline_Always;
   --  Return one logical lane.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : F32x8; Lane : Lane_Index_32x8; With_Value : F32) return F32x8 with Inline_Always;
   --  Return a copy with one lane replaced.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Bit_Cast (Value : F32x8) return U32x8 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  @param Value The value input.
   --  @return The operation result.
   function Bit_Cast (Value : F32x8) return I32x8 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  @param Value The value input.
   --  @return The operation result.
   function Add (Left, Right : F32x8) return F32x8 with Inline_Always;
   --  Apply Add independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract (Left, Right : F32x8) return F32x8 with Inline_Always;
   --  Apply Subtract independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply (Left, Right : F32x8) return F32x8 with Inline_Always;
   --  Apply Multiply independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Divide (Left, Right : F32x8) return F32x8 with Inline_Always;
   --  Apply Divide independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min_Number (Left, Right : F32x8) return F32x8 with Inline_Always;
   --  Apply Min_Number independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max_Number (Left, Right : F32x8) return F32x8 with Inline_Always;
   --  Apply Max_Number independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Equal (Left, Right : F32x8) return Mask_32x8 with Inline_Always;
   --  Apply Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : F32x8) return Mask_32x8 with Inline_Always;
   --  Apply Less_Than independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : F32x8) return Mask_32x8 with Inline_Always;
   --  Apply Less_Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : F32x8) return Mask_32x8 with Inline_Always;
   --  Apply Greater_Than independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : F32x8) return Mask_32x8 with Inline_Always;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Unordered (Left, Right : F32x8) return Mask_32x8 with Inline_Always;
   --  Apply Unordered independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_32x8; If_True, If_False : F32x8) return F32x8 with Inline_Always;
   --  Select one input in each lane according to mask truth.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : F32x8; Mask : Mask_32x8) return F32x8 with Inline_Always;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : F32x8; Mask : Mask_32x8) return F32x8 with Inline_Always;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add (Value : F32x8) return F32 with Inline_Always;
   --  Apply Reduce_Add in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min_Number (Value : F32x8) return F32 with Inline_Always;
   --  Apply Reduce_Min_Number in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max_Number (Value : F32x8) return F32 with Inline_Always;
   --  Apply Reduce_Max_Number in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : F32x8) return F32x8 with Inline_Always;
   --  Reverse logical lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : F32x8; Map : Lane_Map_32x8) return F32x8 with Inline_Always;
   --  Select each result lane through a reusable lane map.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : F32x8; Map : Two_Source_Lane_Map_32x8) return F32x8 with Inline_Always;
   --  Select each result lane from one lane of either input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : F32x8) return F32x8 with Inline_Always;
   --  Apply Interleave_Low with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : F32x8) return F32x8 with Inline_Always;
   --  Apply Interleave_High with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : F32x8) return F32x8 with Inline_Always;
   --  Apply Deinterleave_Even with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : F32x8) return F32x8 with Inline_Always;
   --  Apply Deinterleave_Odd with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : F32x8; Count : Natural) return F32x8 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : F32x8; Count : Natural) return F32x8 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : F32_Array; Start : Natural) return Boolean with Inline_Always;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : F32_Array; Start : Natural) return F32x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector without an alignment requirement.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out F32_Array; Start : Natural; Value : F32x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector without an alignment requirement.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : F32_Array; Start : Natural) return F32x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector from an address with any alignment.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out F32_Array; Start : Natural; Value : F32x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector to an address with any alignment.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : F32_Array; Start : Natural) return F32x8 with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Load one complete vector from a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out F32_Array; Start : Natural; Value : F32x8) with Pre => Start in Data'Range and then 7 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Store one complete vector to a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : F32_Array; Start : Natural; Count : Lane_Count_32x8) return F32x8 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out F32_Array; Start : Natural; Count : Lane_Count_32x8; Value : F32x8) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Write exactly Count elements and leave all others unchanged.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.
   function Zero return F64x4 with Inline_Always;
   --  Return a vector whose lanes are zero.
   --  @return The operation result.
   function Splat (Value : F64) return F64x4 with Inline_Always;
   --  Return a vector whose lanes all contain Value.
   --  @param Value The value input.
   --  @return The operation result.
   function From_Lanes (Values : Lane_Values_F64x4) return F64x4 with Inline_Always;
   --  Construct a vector in logical lane order.
   --  @param Values The values input.
   --  @return The operation result.
   function To_Lanes (Value : F64x4) return Lane_Values_F64x4 with Inline_Always;
   --  Return all lanes in logical lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Extract (Value : F64x4; Lane : Lane_Index_64x4) return F64 with Inline_Always;
   --  Return one logical lane.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @return The operation result.
   function Replace (Value : F64x4; Lane : Lane_Index_64x4; With_Value : F64) return F64x4 with Inline_Always;
   --  Return a copy with one lane replaced.
   --  @param Value The value input.
   --  @param Lane The lane input.
   --  @param With_Value The with value input.
   --  @return The operation result.
   function Bit_Cast (Value : F64x4) return U64x4 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  @param Value The value input.
   --  @return The operation result.
   function Bit_Cast (Value : F64x4) return I64x4 with Inline_Always;
   --  Reinterpret every lane bit pattern without changing lane position.
   --  @param Value The value input.
   --  @return The operation result.
   function Add (Left, Right : F64x4) return F64x4 with Inline_Always;
   --  Apply Add independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Subtract (Left, Right : F64x4) return F64x4 with Inline_Always;
   --  Apply Subtract independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Multiply (Left, Right : F64x4) return F64x4 with Inline_Always;
   --  Apply Multiply independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Divide (Left, Right : F64x4) return F64x4 with Inline_Always;
   --  Apply Divide independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Min_Number (Left, Right : F64x4) return F64x4 with Inline_Always;
   --  Apply Min_Number independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Max_Number (Left, Right : F64x4) return F64x4 with Inline_Always;
   --  Apply Max_Number independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Equal (Left, Right : F64x4) return Mask_64x4 with Inline_Always;
   --  Apply Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Than (Left, Right : F64x4) return Mask_64x4 with Inline_Always;
   --  Apply Less_Than independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Less_Equal (Left, Right : F64x4) return Mask_64x4 with Inline_Always;
   --  Apply Less_Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Than (Left, Right : F64x4) return Mask_64x4 with Inline_Always;
   --  Apply Greater_Than independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Greater_Equal (Left, Right : F64x4) return Mask_64x4 with Inline_Always;
   --  Apply Greater_Equal independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Unordered (Left, Right : F64x4) return Mask_64x4 with Inline_Always;
   --  Apply Unordered independently to corresponding lanes.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Select_Value (Mask : Mask_64x4; If_True, If_False : F64x4) return F64x4 with Inline_Always;
   --  Select one input in each lane according to mask truth.
   --  @param Mask The mask input.
   --  @param If_True The if true input.
   --  @param If_False The if false input.
   --  @return The operation result.
   function Compress (Value : F64x4; Mask : Mask_64x4) return F64x4 with Inline_Always;
   --  Stably pack true-mask lanes toward lane zero and zero-fill the remainder.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Expand (Value : F64x4; Mask : Mask_64x4) return F64x4 with Inline_Always;
   --  Place consecutive low input lanes into true-mask positions and zero-fill false positions.
   --  @param Value The value input.
   --  @param Mask The mask input.
   --  @return The operation result.
   function Reduce_Add (Value : F64x4) return F64 with Inline_Always;
   --  Apply Reduce_Add in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Min_Number (Value : F64x4) return F64 with Inline_Always;
   --  Apply Reduce_Min_Number in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reduce_Max_Number (Value : F64x4) return F64 with Inline_Always;
   --  Apply Reduce_Max_Number in ascending lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Reverse_Lanes (Value : F64x4) return F64x4 with Inline_Always;
   --  Reverse logical lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Permute_Lanes (Value : F64x4; Map : Lane_Map_64x4) return F64x4 with Inline_Always;
   --  Select each result lane through a reusable lane map.
   --  @param Value The value input.
   --  @param Map The map input.
   --  @return The operation result.
   function Permute_Lanes (Left, Right : F64x4; Map : Two_Source_Lane_Map_64x4) return F64x4 with Inline_Always;
   --  Select each result lane from one lane of either input.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @param Map The map input.
   --  @return The operation result.
   function Interleave_Low (Left, Right : F64x4) return F64x4 with Inline_Always;
   --  Apply Interleave_Low with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Interleave_High (Left, Right : F64x4) return F64x4 with Inline_Always;
   --  Apply Interleave_High with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Even (Left, Right : F64x4) return F64x4 with Inline_Always;
   --  Apply Deinterleave_Even with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Deinterleave_Odd (Left, Right : F64x4) return F64x4 with Inline_Always;
   --  Apply Deinterleave_Odd with the documented lane mapping.
   --  @param Left The left input.
   --  @param Right The right input.
   --  @return The operation result.
   function Slide_Lanes_Toward_Low (Value : F64x4; Count : Natural) return F64x4 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Slide_Lanes_Toward_High (Value : F64x4; Count : Natural) return F64x4 with Inline_Always;
   --  Move retained lanes and zero-fill vacated lanes.
   --  @param Value The value input.
   --  @param Count The count input.
   --  @return The operation result.
   function Is_Aligned_32 (Data : F64_Array; Start : Natural) return Boolean with Inline_Always;
   --  Report whether the selected first element has a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   function Load (Data : F64_Array; Start : Natural) return F64x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector without an alignment requirement.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store (Data : in out F64_Array; Start : Natural; Value : F64x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector without an alignment requirement.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Unaligned (Data : F64_Array; Start : Natural) return F64x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start), Inline_Always;
   --  Load one complete vector from an address with any alignment.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Unaligned (Data : in out F64_Array; Start : Natural; Value : F64x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start), Inline_Always;
   --  Store one complete vector to an address with any alignment.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Aligned (Data : F64_Array; Start : Natural) return F64x4 with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Load one complete vector from a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @return The operation result.
   procedure Store_Aligned (Data : in out F64_Array; Start : Natural; Value : F64x4) with Pre => Start in Data'Range and then 3 <= Natural (Data'Last - Start) and then Is_Aligned_32 (Data, Start), Inline_Always;
   --  Store one complete vector to a 32-byte-aligned address.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Value The value input.
   function Load_Partial (Data : F64_Array; Start : Natural; Count : Lane_Count_64x4) return F64x4 with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Read exactly Count elements and zero-fill remaining lanes.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @return The operation result.
   procedure Store_Partial (Data : in out F64_Array; Start : Natural; Count : Lane_Count_64x4; Value : F64x4) with Pre => Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start)), Inline_Always;
   --  Write exactly Count elements and leave all others unchanged.
   --  @param Data The data input.
   --  @param Start The start input.
   --  @param Count The count input.
   --  @param Value The value input.

   function Widen_Low (Value : U8x32) return U16x16 with Inline_Always;
   --  Widen the low integer source half exactly, preserve signedness, and preserve lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_High (Value : U8x32) return U16x16 with Inline_Always;
   --  Widen the high integer source half exactly, preserve signedness, and preserve lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_Low (Value : I8x32) return I16x16 with Inline_Always;
   --  Widen the low integer source half exactly, preserve signedness, and preserve lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_High (Value : I8x32) return I16x16 with Inline_Always;
   --  Widen the high integer source half exactly, preserve signedness, and preserve lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_Low (Value : U16x16) return U32x8 with Inline_Always;
   --  Widen the low integer source half exactly, preserve signedness, and preserve lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_High (Value : U16x16) return U32x8 with Inline_Always;
   --  Widen the high integer source half exactly, preserve signedness, and preserve lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_Low (Value : I16x16) return I32x8 with Inline_Always;
   --  Widen the low integer source half exactly, preserve signedness, and preserve lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_High (Value : I16x16) return I32x8 with Inline_Always;
   --  Widen the high integer source half exactly, preserve signedness, and preserve lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_Low (Value : U32x8) return U64x4 with Inline_Always;
   --  Widen the low integer source half exactly, preserve signedness, and preserve lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_High (Value : U32x8) return U64x4 with Inline_Always;
   --  Widen the high integer source half exactly, preserve signedness, and preserve lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_Low (Value : I32x8) return I64x4 with Inline_Always;
   --  Widen the low integer source half exactly, preserve signedness, and preserve lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_High (Value : I32x8) return I64x4 with Inline_Always;
   --  Widen the high integer source half exactly, preserve signedness, and preserve lane order.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_Low (Value : F32x8) return F64x4 with Inline_Always;
   --  Widen the low binary32 source half to binary64 and preserve lane order. Finite values convert exactly. Signed zero and infinity are preserved. A NaN produces a NaN with unspecified payload and signaling state.
   --  @param Value The value input.
   --  @return The operation result.
   function Widen_High (Value : F32x8) return F64x4 with Inline_Always;
   --  Widen the high binary32 source half to binary64 and preserve lane order. Finite values convert exactly. Signed zero and infinity are preserved. A NaN produces a NaN with unspecified payload and signaling state.
   --  @param Value The value input.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : U16x16) return U8x32 with Inline_Always;
   --  Keep the low bits of every source lane and concatenate Low before High.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : U16x16) return U8x32 with Inline_Always;
   --  Clamp every source lane to the result range and concatenate Low before High.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : I16x16) return I8x32 with Inline_Always;
   --  Keep the low bits of every source lane and concatenate Low before High.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I16x16) return I8x32 with Inline_Always;
   --  Clamp every source lane to the result range and concatenate Low before High.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : U32x8) return U16x16 with Inline_Always;
   --  Keep the low bits of every source lane and concatenate Low before High.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : U32x8) return U16x16 with Inline_Always;
   --  Clamp every source lane to the result range and concatenate Low before High.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : I32x8) return I16x16 with Inline_Always;
   --  Keep the low bits of every source lane and concatenate Low before High.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I32x8) return I16x16 with Inline_Always;
   --  Clamp every source lane to the result range and concatenate Low before High.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : U64x4) return U32x8 with Inline_Always;
   --  Keep the low bits of every source lane and concatenate Low before High.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : U64x4) return U32x8 with Inline_Always;
   --  Clamp every source lane to the result range and concatenate Low before High.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Truncate (Low, High : I64x4) return I32x8 with Inline_Always;
   --  Keep the low bits of every source lane and concatenate Low before High.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I64x4) return I32x8 with Inline_Always;
   --  Clamp every source lane to the result range and concatenate Low before High.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I16x16) return U8x32 with Inline_Always;
   --  Clamp signed lanes to the unsigned result range and concatenate Low before High.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I32x8) return U16x16 with Inline_Always;
   --  Clamp signed lanes to the unsigned result range and concatenate Low before High.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Saturate (Low, High : I64x4) return U32x8 with Inline_Always;
   --  Clamp signed lanes to the unsigned result range and concatenate Low before High.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Narrow_Round (Low, High : F64x4) return F32x8 with Inline_Always;
   --  With the default round-to-nearest, ties-to-even environment, round binary64 lanes to binary32 and concatenate Low before High. Preserve signed zero and infinity. Use gradual underflow and signed overflow to infinity. A NaN remains a NaN with unspecified payload and signaling state. Do not modify the floating-point control register.
   --  @param Low The low input.
   --  @param High The high input.
   --  @return The operation result.
   function Convert_Round (Value : I32x8) return F32x8 with Inline_Always;
   --  With the default round-to-nearest, ties-to-even environment, convert corresponding integer lanes to finite floating lanes. Do not modify the floating-point control register.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Round (Value : U32x8) return F32x8 with Inline_Always;
   --  With the default round-to-nearest, ties-to-even environment, convert corresponding integer lanes to finite floating lanes. Do not modify the floating-point control register.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Round (Value : I64x4) return F64x4 with Inline_Always;
   --  With the default round-to-nearest, ties-to-even environment, convert corresponding integer lanes to finite floating lanes. Do not modify the floating-point control register.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Round (Value : U64x4) return F64x4 with Inline_Always;
   --  With the default round-to-nearest, ties-to-even environment, convert corresponding integer lanes to finite floating lanes. Do not modify the floating-point control register.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Truncate_Saturate (Value : F32x8) return I32x8 with Inline_Always;
   --  Truncate finite floating lanes toward zero and clamp to the integer result range. Map NaN to zero. Map positive infinity to the destination maximum. Map negative infinity to the signed minimum or unsigned zero. Do not depend on or modify the floating-point rounding mode.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Truncate_Saturate (Value : F32x8) return U32x8 with Inline_Always;
   --  Truncate finite floating lanes toward zero and clamp to the integer result range. Map NaN to zero. Map positive infinity to the destination maximum. Map negative infinity to the signed minimum or unsigned zero. Do not depend on or modify the floating-point rounding mode.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Truncate_Saturate (Value : F64x4) return I64x4 with Inline_Always;
   --  Truncate finite floating lanes toward zero and clamp to the integer result range. Map NaN to zero. Map positive infinity to the destination maximum. Map negative infinity to the signed minimum or unsigned zero. Do not depend on or modify the floating-point rounding mode.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Truncate_Saturate (Value : F64x4) return U64x4 with Inline_Always;
   --  Truncate finite floating lanes toward zero and clamp to the integer result range. Map NaN to zero. Map positive infinity to the destination maximum. Map negative infinity to the signed minimum or unsigned zero. Do not depend on or modify the floating-point rounding mode.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Saturate (Value : I8x32) return U8x32 with Inline_Always;
   --  Convert signed lanes to unsigned, clamp negative values to zero, and preserve other values.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Saturate (Value : U8x32) return I8x32 with Inline_Always;
   --  Convert unsigned lanes to signed, clamp values above the signed maximum, and preserve other values.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Saturate (Value : I16x16) return U16x16 with Inline_Always;
   --  Convert signed lanes to unsigned, clamp negative values to zero, and preserve other values.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Saturate (Value : U16x16) return I16x16 with Inline_Always;
   --  Convert unsigned lanes to signed, clamp values above the signed maximum, and preserve other values.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Saturate (Value : I32x8) return U32x8 with Inline_Always;
   --  Convert signed lanes to unsigned, clamp negative values to zero, and preserve other values.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Saturate (Value : U32x8) return I32x8 with Inline_Always;
   --  Convert unsigned lanes to signed, clamp values above the signed maximum, and preserve other values.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Saturate (Value : I64x4) return U64x4 with Inline_Always;
   --  Convert signed lanes to unsigned, clamp negative values to zero, and preserve other values.
   --  @param Value The value input.
   --  @return The operation result.
   function Convert_Saturate (Value : U64x4) return I64x4 with Inline_Always;
   --  Convert unsigned lanes to signed, clamp values above the signed maximum, and preserve other values.
   --  @param Value The value input.
   --  @return The operation result.
end Flyology_SIMD.Wide.Native;
