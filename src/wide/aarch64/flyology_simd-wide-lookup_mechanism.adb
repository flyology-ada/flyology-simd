with System.Machine_Code;

package body Flyology_SIMD.Wide.Lookup_Mechanism is
   use System.Machine_Code;

   function Table_Lookup_Half
     (Table_Low, Table_High, Indices : U8x16) return U8x16
   is
      Result : U8x16;
   begin
      Asm
        (Template =>
           "ldr q0, [%1]" & ASCII.LF & ASCII.HT &
           "ldr q1, [%2]" & ASCII.LF & ASCII.HT &
           "ldr q2, [%3]" & ASCII.LF & ASCII.HT &
           "tbl v0.16b, {v0.16b, v1.16b}, v2.16b" & ASCII.LF & ASCII.HT &
           "str q0, [%0]",
         Inputs =>
           [System.Address'Asm_Input ("r", Result'Address),
            System.Address'Asm_Input ("r", Table_Low'Address),
            System.Address'Asm_Input ("r", Table_High'Address),
            System.Address'Asm_Input ("r", Indices'Address)],
         Clobber => "v0,v1,v2,memory",
         Volatile => True);
      return Result;
   end Table_Lookup_Half;

   function Table_Lookup_32
     (Table, Indices : U8x32) return U8x32 is
     ((Low => Table_Lookup_Half (Table.Low, Table.High, Indices.Low),
       High => Table_Lookup_Half (Table.Low, Table.High, Indices.High)));
end Flyology_SIMD.Wide.Lookup_Mechanism;
