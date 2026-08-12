private package Flyology_SIMD.Wide.Permute_Mechanism
  with Preelaborate
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
end Flyology_SIMD.Wide.Permute_Mechanism;
