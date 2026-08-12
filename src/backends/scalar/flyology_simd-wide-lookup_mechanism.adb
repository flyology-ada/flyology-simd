package body Flyology_SIMD.Wide.Lookup_Mechanism is
   use type U8;

   function Table_Lookup_32
     (Table_Low, Table_High, Indices : U8x16) return U8x16
   is
      Low_Lanes : constant Lane_Values_8x16 :=
        Flyology_SIMD.To_Lanes (Table_Low);
      High_Lanes : constant Lane_Values_8x16 :=
        Flyology_SIMD.To_Lanes (Table_High);
      Index_Lanes : constant Lane_Values_8x16 :=
        Flyology_SIMD.To_Lanes (Indices);
      Result : Lane_Values_8x16 := [others => 0];
   begin
      for Lane in Lane_Index_8x16 loop
         if Index_Lanes (Lane) <= 15 then
            Result (Lane) := Low_Lanes (Natural (Index_Lanes (Lane)));
         elsif Index_Lanes (Lane) <= 31 then
            Result (Lane) :=
              High_Lanes (Natural (Index_Lanes (Lane)) - 16);
         end if;
      end loop;
      return Flyology_SIMD.From_Lanes (Result);
   end Table_Lookup_32;
end Flyology_SIMD.Wide.Lookup_Mechanism;
