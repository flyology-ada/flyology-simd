private package Flyology_SIMD.Wide.Permute_Mechanism
  with Preelaborate, SPARK_Mode => On
is
   --  Target-selected mechanism for reusable Wide lane maps.

   function Permute_Lanes (Value : U8x32; Map : Lane_Map_8x32) return U8x32
     with Inline_Always;
   --  Select each result lane from one source through Map.
   --  @param Value The source lanes.
   --  @param Map The reusable one-source lane map.
   --  @return The selected lanes in result-lane order.
   function Permute_Lanes (Left, Right : U8x32; Map : Two_Source_Lane_Map_8x32) return U8x32
     with Inline_Always;
   --  Select each result lane from Left or Right through Map.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @param Map The reusable two-source lane map.
   --  @return The selected lanes in result-lane order.
   function Reverse_Lanes (Value : U8x32) return U8x32
     with Inline_Always;
   --  Reverse logical lane order.
   --  @param Value The source lanes.
   --  @return The lanes in reverse order.
   function Interleave_Low (Left, Right : U8x32) return U8x32
     with Inline_Always;
   --  Interleave the low halves of two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The interleaved low halves.
   function Interleave_High (Left, Right : U8x32) return U8x32
     with Inline_Always;
   --  Interleave the high halves of two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The interleaved high halves.
   function Deinterleave_Even (Left, Right : U8x32) return U8x32
     with Inline_Always;
   --  Gather even lanes from two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The even lanes of Left followed by those of Right.
   function Deinterleave_Odd (Left, Right : U8x32) return U8x32
     with Inline_Always;
   --  Gather odd lanes from two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The odd lanes of Left followed by those of Right.
   function Slide_Lanes_Toward_Low (Value : U8x32; Count : Natural) return U8x32
     with Inline_Always;
   --  Slide lanes toward lower indexes and zero-fill the high lanes.
   --  @param Value The source lanes.
   --  @param Count The lane displacement.
   --  @return The slid lanes, or zero when Count reaches or exceeds the width.
   function Slide_Lanes_Toward_High (Value : U8x32; Count : Natural) return U8x32
     with Inline_Always;
   --  Slide lanes toward higher indexes and zero-fill the low lanes.
   --  @param Value The source lanes.
   --  @param Count The lane displacement.
   --  @return The slid lanes, or zero when Count reaches or exceeds the width.
   function Permute_Lanes (Value : I8x32; Map : Lane_Map_8x32) return I8x32
     with Inline_Always;
   --  Select each result lane from one source through Map.
   --  @param Value The source lanes.
   --  @param Map The reusable one-source lane map.
   --  @return The selected lanes in result-lane order.
   function Permute_Lanes (Left, Right : I8x32; Map : Two_Source_Lane_Map_8x32) return I8x32
     with Inline_Always;
   --  Select each result lane from Left or Right through Map.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @param Map The reusable two-source lane map.
   --  @return The selected lanes in result-lane order.
   function Reverse_Lanes (Value : I8x32) return I8x32
     with Inline_Always;
   --  Reverse logical lane order.
   --  @param Value The source lanes.
   --  @return The lanes in reverse order.
   function Interleave_Low (Left, Right : I8x32) return I8x32
     with Inline_Always;
   --  Interleave the low halves of two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The interleaved low halves.
   function Interleave_High (Left, Right : I8x32) return I8x32
     with Inline_Always;
   --  Interleave the high halves of two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The interleaved high halves.
   function Deinterleave_Even (Left, Right : I8x32) return I8x32
     with Inline_Always;
   --  Gather even lanes from two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The even lanes of Left followed by those of Right.
   function Deinterleave_Odd (Left, Right : I8x32) return I8x32
     with Inline_Always;
   --  Gather odd lanes from two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The odd lanes of Left followed by those of Right.
   function Slide_Lanes_Toward_Low (Value : I8x32; Count : Natural) return I8x32
     with Inline_Always;
   --  Slide lanes toward lower indexes and zero-fill the high lanes.
   --  @param Value The source lanes.
   --  @param Count The lane displacement.
   --  @return The slid lanes, or zero when Count reaches or exceeds the width.
   function Slide_Lanes_Toward_High (Value : I8x32; Count : Natural) return I8x32
     with Inline_Always;
   --  Slide lanes toward higher indexes and zero-fill the low lanes.
   --  @param Value The source lanes.
   --  @param Count The lane displacement.
   --  @return The slid lanes, or zero when Count reaches or exceeds the width.
   function Permute_Lanes (Value : U16x16; Map : Lane_Map_16x16) return U16x16
     with Inline_Always;
   --  Select each result lane from one source through Map.
   --  @param Value The source lanes.
   --  @param Map The reusable one-source lane map.
   --  @return The selected lanes in result-lane order.
   function Permute_Lanes (Left, Right : U16x16; Map : Two_Source_Lane_Map_16x16) return U16x16
     with Inline_Always;
   --  Select each result lane from Left or Right through Map.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @param Map The reusable two-source lane map.
   --  @return The selected lanes in result-lane order.
   function Reverse_Lanes (Value : U16x16) return U16x16
     with Inline_Always;
   --  Reverse logical lane order.
   --  @param Value The source lanes.
   --  @return The lanes in reverse order.
   function Interleave_Low (Left, Right : U16x16) return U16x16
     with Inline_Always;
   --  Interleave the low halves of two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The interleaved low halves.
   function Interleave_High (Left, Right : U16x16) return U16x16
     with Inline_Always;
   --  Interleave the high halves of two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The interleaved high halves.
   function Deinterleave_Even (Left, Right : U16x16) return U16x16
     with Inline_Always;
   --  Gather even lanes from two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The even lanes of Left followed by those of Right.
   function Deinterleave_Odd (Left, Right : U16x16) return U16x16
     with Inline_Always;
   --  Gather odd lanes from two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The odd lanes of Left followed by those of Right.
   function Slide_Lanes_Toward_Low (Value : U16x16; Count : Natural) return U16x16
     with Inline_Always;
   --  Slide lanes toward lower indexes and zero-fill the high lanes.
   --  @param Value The source lanes.
   --  @param Count The lane displacement.
   --  @return The slid lanes, or zero when Count reaches or exceeds the width.
   function Slide_Lanes_Toward_High (Value : U16x16; Count : Natural) return U16x16
     with Inline_Always;
   --  Slide lanes toward higher indexes and zero-fill the low lanes.
   --  @param Value The source lanes.
   --  @param Count The lane displacement.
   --  @return The slid lanes, or zero when Count reaches or exceeds the width.
   function Permute_Lanes (Value : I16x16; Map : Lane_Map_16x16) return I16x16
     with Inline_Always;
   --  Select each result lane from one source through Map.
   --  @param Value The source lanes.
   --  @param Map The reusable one-source lane map.
   --  @return The selected lanes in result-lane order.
   function Permute_Lanes (Left, Right : I16x16; Map : Two_Source_Lane_Map_16x16) return I16x16
     with Inline_Always;
   --  Select each result lane from Left or Right through Map.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @param Map The reusable two-source lane map.
   --  @return The selected lanes in result-lane order.
   function Reverse_Lanes (Value : I16x16) return I16x16
     with Inline_Always;
   --  Reverse logical lane order.
   --  @param Value The source lanes.
   --  @return The lanes in reverse order.
   function Interleave_Low (Left, Right : I16x16) return I16x16
     with Inline_Always;
   --  Interleave the low halves of two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The interleaved low halves.
   function Interleave_High (Left, Right : I16x16) return I16x16
     with Inline_Always;
   --  Interleave the high halves of two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The interleaved high halves.
   function Deinterleave_Even (Left, Right : I16x16) return I16x16
     with Inline_Always;
   --  Gather even lanes from two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The even lanes of Left followed by those of Right.
   function Deinterleave_Odd (Left, Right : I16x16) return I16x16
     with Inline_Always;
   --  Gather odd lanes from two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The odd lanes of Left followed by those of Right.
   function Slide_Lanes_Toward_Low (Value : I16x16; Count : Natural) return I16x16
     with Inline_Always;
   --  Slide lanes toward lower indexes and zero-fill the high lanes.
   --  @param Value The source lanes.
   --  @param Count The lane displacement.
   --  @return The slid lanes, or zero when Count reaches or exceeds the width.
   function Slide_Lanes_Toward_High (Value : I16x16; Count : Natural) return I16x16
     with Inline_Always;
   --  Slide lanes toward higher indexes and zero-fill the low lanes.
   --  @param Value The source lanes.
   --  @param Count The lane displacement.
   --  @return The slid lanes, or zero when Count reaches or exceeds the width.
   function Permute_Lanes (Value : U32x8; Map : Lane_Map_32x8) return U32x8
     with Inline_Always;
   --  Select each result lane from one source through Map.
   --  @param Value The source lanes.
   --  @param Map The reusable one-source lane map.
   --  @return The selected lanes in result-lane order.
   function Permute_Lanes (Left, Right : U32x8; Map : Two_Source_Lane_Map_32x8) return U32x8
     with Inline_Always;
   --  Select each result lane from Left or Right through Map.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @param Map The reusable two-source lane map.
   --  @return The selected lanes in result-lane order.
   function Reverse_Lanes (Value : U32x8) return U32x8
     with Inline_Always;
   --  Reverse logical lane order.
   --  @param Value The source lanes.
   --  @return The lanes in reverse order.
   function Interleave_Low (Left, Right : U32x8) return U32x8
     with Inline_Always;
   --  Interleave the low halves of two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The interleaved low halves.
   function Interleave_High (Left, Right : U32x8) return U32x8
     with Inline_Always;
   --  Interleave the high halves of two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The interleaved high halves.
   function Deinterleave_Even (Left, Right : U32x8) return U32x8
     with Inline_Always;
   --  Gather even lanes from two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The even lanes of Left followed by those of Right.
   function Deinterleave_Odd (Left, Right : U32x8) return U32x8
     with Inline_Always;
   --  Gather odd lanes from two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The odd lanes of Left followed by those of Right.
   function Slide_Lanes_Toward_Low (Value : U32x8; Count : Natural) return U32x8
     with Inline_Always;
   --  Slide lanes toward lower indexes and zero-fill the high lanes.
   --  @param Value The source lanes.
   --  @param Count The lane displacement.
   --  @return The slid lanes, or zero when Count reaches or exceeds the width.
   function Slide_Lanes_Toward_High (Value : U32x8; Count : Natural) return U32x8
     with Inline_Always;
   --  Slide lanes toward higher indexes and zero-fill the low lanes.
   --  @param Value The source lanes.
   --  @param Count The lane displacement.
   --  @return The slid lanes, or zero when Count reaches or exceeds the width.
   function Permute_Lanes (Value : I32x8; Map : Lane_Map_32x8) return I32x8
     with Inline_Always;
   --  Select each result lane from one source through Map.
   --  @param Value The source lanes.
   --  @param Map The reusable one-source lane map.
   --  @return The selected lanes in result-lane order.
   function Permute_Lanes (Left, Right : I32x8; Map : Two_Source_Lane_Map_32x8) return I32x8
     with Inline_Always;
   --  Select each result lane from Left or Right through Map.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @param Map The reusable two-source lane map.
   --  @return The selected lanes in result-lane order.
   function Reverse_Lanes (Value : I32x8) return I32x8
     with Inline_Always;
   --  Reverse logical lane order.
   --  @param Value The source lanes.
   --  @return The lanes in reverse order.
   function Interleave_Low (Left, Right : I32x8) return I32x8
     with Inline_Always;
   --  Interleave the low halves of two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The interleaved low halves.
   function Interleave_High (Left, Right : I32x8) return I32x8
     with Inline_Always;
   --  Interleave the high halves of two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The interleaved high halves.
   function Deinterleave_Even (Left, Right : I32x8) return I32x8
     with Inline_Always;
   --  Gather even lanes from two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The even lanes of Left followed by those of Right.
   function Deinterleave_Odd (Left, Right : I32x8) return I32x8
     with Inline_Always;
   --  Gather odd lanes from two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The odd lanes of Left followed by those of Right.
   function Slide_Lanes_Toward_Low (Value : I32x8; Count : Natural) return I32x8
     with Inline_Always;
   --  Slide lanes toward lower indexes and zero-fill the high lanes.
   --  @param Value The source lanes.
   --  @param Count The lane displacement.
   --  @return The slid lanes, or zero when Count reaches or exceeds the width.
   function Slide_Lanes_Toward_High (Value : I32x8; Count : Natural) return I32x8
     with Inline_Always;
   --  Slide lanes toward higher indexes and zero-fill the low lanes.
   --  @param Value The source lanes.
   --  @param Count The lane displacement.
   --  @return The slid lanes, or zero when Count reaches or exceeds the width.
   function Permute_Lanes (Value : U64x4; Map : Lane_Map_64x4) return U64x4
     with Inline_Always;
   --  Select each result lane from one source through Map.
   --  @param Value The source lanes.
   --  @param Map The reusable one-source lane map.
   --  @return The selected lanes in result-lane order.
   function Permute_Lanes (Left, Right : U64x4; Map : Two_Source_Lane_Map_64x4) return U64x4
     with Inline_Always;
   --  Select each result lane from Left or Right through Map.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @param Map The reusable two-source lane map.
   --  @return The selected lanes in result-lane order.
   function Reverse_Lanes (Value : U64x4) return U64x4
     with Inline_Always;
   --  Reverse logical lane order.
   --  @param Value The source lanes.
   --  @return The lanes in reverse order.
   function Interleave_Low (Left, Right : U64x4) return U64x4
     with Inline_Always;
   --  Interleave the low halves of two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The interleaved low halves.
   function Interleave_High (Left, Right : U64x4) return U64x4
     with Inline_Always;
   --  Interleave the high halves of two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The interleaved high halves.
   function Deinterleave_Even (Left, Right : U64x4) return U64x4
     with Inline_Always;
   --  Gather even lanes from two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The even lanes of Left followed by those of Right.
   function Deinterleave_Odd (Left, Right : U64x4) return U64x4
     with Inline_Always;
   --  Gather odd lanes from two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The odd lanes of Left followed by those of Right.
   function Slide_Lanes_Toward_Low (Value : U64x4; Count : Natural) return U64x4
     with Inline_Always;
   --  Slide lanes toward lower indexes and zero-fill the high lanes.
   --  @param Value The source lanes.
   --  @param Count The lane displacement.
   --  @return The slid lanes, or zero when Count reaches or exceeds the width.
   function Slide_Lanes_Toward_High (Value : U64x4; Count : Natural) return U64x4
     with Inline_Always;
   --  Slide lanes toward higher indexes and zero-fill the low lanes.
   --  @param Value The source lanes.
   --  @param Count The lane displacement.
   --  @return The slid lanes, or zero when Count reaches or exceeds the width.
   function Permute_Lanes (Value : I64x4; Map : Lane_Map_64x4) return I64x4
     with Inline_Always;
   --  Select each result lane from one source through Map.
   --  @param Value The source lanes.
   --  @param Map The reusable one-source lane map.
   --  @return The selected lanes in result-lane order.
   function Permute_Lanes (Left, Right : I64x4; Map : Two_Source_Lane_Map_64x4) return I64x4
     with Inline_Always;
   --  Select each result lane from Left or Right through Map.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @param Map The reusable two-source lane map.
   --  @return The selected lanes in result-lane order.
   function Reverse_Lanes (Value : I64x4) return I64x4
     with Inline_Always;
   --  Reverse logical lane order.
   --  @param Value The source lanes.
   --  @return The lanes in reverse order.
   function Interleave_Low (Left, Right : I64x4) return I64x4
     with Inline_Always;
   --  Interleave the low halves of two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The interleaved low halves.
   function Interleave_High (Left, Right : I64x4) return I64x4
     with Inline_Always;
   --  Interleave the high halves of two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The interleaved high halves.
   function Deinterleave_Even (Left, Right : I64x4) return I64x4
     with Inline_Always;
   --  Gather even lanes from two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The even lanes of Left followed by those of Right.
   function Deinterleave_Odd (Left, Right : I64x4) return I64x4
     with Inline_Always;
   --  Gather odd lanes from two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The odd lanes of Left followed by those of Right.
   function Slide_Lanes_Toward_Low (Value : I64x4; Count : Natural) return I64x4
     with Inline_Always;
   --  Slide lanes toward lower indexes and zero-fill the high lanes.
   --  @param Value The source lanes.
   --  @param Count The lane displacement.
   --  @return The slid lanes, or zero when Count reaches or exceeds the width.
   function Slide_Lanes_Toward_High (Value : I64x4; Count : Natural) return I64x4
     with Inline_Always;
   --  Slide lanes toward higher indexes and zero-fill the low lanes.
   --  @param Value The source lanes.
   --  @param Count The lane displacement.
   --  @return The slid lanes, or zero when Count reaches or exceeds the width.
   function Permute_Lanes (Value : F32x8; Map : Lane_Map_32x8) return F32x8
     with Inline_Always;
   --  Select each result lane from one source through Map.
   --  @param Value The source lanes.
   --  @param Map The reusable one-source lane map.
   --  @return The selected lanes in result-lane order.
   function Permute_Lanes (Left, Right : F32x8; Map : Two_Source_Lane_Map_32x8) return F32x8
     with Inline_Always;
   --  Select each result lane from Left or Right through Map.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @param Map The reusable two-source lane map.
   --  @return The selected lanes in result-lane order.
   function Reverse_Lanes (Value : F32x8) return F32x8
     with Inline_Always;
   --  Reverse logical lane order.
   --  @param Value The source lanes.
   --  @return The lanes in reverse order.
   function Interleave_Low (Left, Right : F32x8) return F32x8
     with Inline_Always;
   --  Interleave the low halves of two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The interleaved low halves.
   function Interleave_High (Left, Right : F32x8) return F32x8
     with Inline_Always;
   --  Interleave the high halves of two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The interleaved high halves.
   function Deinterleave_Even (Left, Right : F32x8) return F32x8
     with Inline_Always;
   --  Gather even lanes from two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The even lanes of Left followed by those of Right.
   function Deinterleave_Odd (Left, Right : F32x8) return F32x8
     with Inline_Always;
   --  Gather odd lanes from two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The odd lanes of Left followed by those of Right.
   function Slide_Lanes_Toward_Low (Value : F32x8; Count : Natural) return F32x8
     with Inline_Always;
   --  Slide lanes toward lower indexes and zero-fill the high lanes.
   --  @param Value The source lanes.
   --  @param Count The lane displacement.
   --  @return The slid lanes, or zero when Count reaches or exceeds the width.
   function Slide_Lanes_Toward_High (Value : F32x8; Count : Natural) return F32x8
     with Inline_Always;
   --  Slide lanes toward higher indexes and zero-fill the low lanes.
   --  @param Value The source lanes.
   --  @param Count The lane displacement.
   --  @return The slid lanes, or zero when Count reaches or exceeds the width.
   function Permute_Lanes (Value : F64x4; Map : Lane_Map_64x4) return F64x4
     with Inline_Always;
   --  Select each result lane from one source through Map.
   --  @param Value The source lanes.
   --  @param Map The reusable one-source lane map.
   --  @return The selected lanes in result-lane order.
   function Permute_Lanes (Left, Right : F64x4; Map : Two_Source_Lane_Map_64x4) return F64x4
     with Inline_Always;
   --  Select each result lane from Left or Right through Map.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @param Map The reusable two-source lane map.
   --  @return The selected lanes in result-lane order.
   function Reverse_Lanes (Value : F64x4) return F64x4
     with Inline_Always;
   --  Reverse logical lane order.
   --  @param Value The source lanes.
   --  @return The lanes in reverse order.
   function Interleave_Low (Left, Right : F64x4) return F64x4
     with Inline_Always;
   --  Interleave the low halves of two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The interleaved low halves.
   function Interleave_High (Left, Right : F64x4) return F64x4
     with Inline_Always;
   --  Interleave the high halves of two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The interleaved high halves.
   function Deinterleave_Even (Left, Right : F64x4) return F64x4
     with Inline_Always;
   --  Gather even lanes from two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The even lanes of Left followed by those of Right.
   function Deinterleave_Odd (Left, Right : F64x4) return F64x4
     with Inline_Always;
   --  Gather odd lanes from two inputs.
   --  @param Left The left source lanes.
   --  @param Right The right source lanes.
   --  @return The odd lanes of Left followed by those of Right.
   function Slide_Lanes_Toward_Low (Value : F64x4; Count : Natural) return F64x4
     with Inline_Always;
   --  Slide lanes toward lower indexes and zero-fill the high lanes.
   --  @param Value The source lanes.
   --  @param Count The lane displacement.
   --  @return The slid lanes, or zero when Count reaches or exceeds the width.
   function Slide_Lanes_Toward_High (Value : F64x4; Count : Natural) return F64x4
     with Inline_Always;
   --  Slide lanes toward higher indexes and zero-fill the low lanes.
   --  @param Value The source lanes.
   --  @param Count The lane displacement.
   --  @return The slid lanes, or zero when Count reaches or exceeds the width.
end Flyology_SIMD.Wide.Permute_Mechanism;
