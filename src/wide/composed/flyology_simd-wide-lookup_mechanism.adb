with Flyology_SIMD.Backends.Native;

package body Flyology_SIMD.Wide.Lookup_Mechanism is
   package Selected renames Flyology_SIMD.Backends.Native;

   function Table_Lookup_32
     (Table, Indices : U8x32) return U8x32
   is
      Sixteen : constant U8x16 := Selected.Splat (16);
      Low_Indexes : constant U8x16 :=
        Selected.Subtract_Wrap (Indices.Low, Sixteen);
      High_Indexes : constant U8x16 :=
        Selected.Subtract_Wrap (Indices.High, Sixteen);
   begin
      return
        (Low => Selected.Bitwise_Or
           (Selected.Table_Lookup (Table.Low, Indices.Low),
            Selected.Table_Lookup (Table.High, Low_Indexes)),
         High => Selected.Bitwise_Or
           (Selected.Table_Lookup (Table.Low, Indices.High),
            Selected.Table_Lookup (Table.High, High_Indexes)));
   end Table_Lookup_32;
end Flyology_SIMD.Wide.Lookup_Mechanism;
