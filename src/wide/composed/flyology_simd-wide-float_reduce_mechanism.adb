with Flyology_SIMD.Wide.Float_Reduce_Selected_Leaf;

package body Flyology_SIMD.Wide.Float_Reduce_Mechanism is
   package Selected renames Flyology_SIMD.Wide.Float_Reduce_Selected_Leaf;
   function Reduce_Add (Value : F32x8) return F32 is
     (Selected.Reduce_Add (Value));
   function Reduce_Min_Number (Value : F32x8) return F32 is
     (Selected.Reduce_Min_Number (Value));
   function Reduce_Max_Number (Value : F32x8) return F32 is
     (Selected.Reduce_Max_Number (Value));
   function Reduce_Add (Value : F64x4) return F64 is
     (Selected.Reduce_Add (Value));
   function Reduce_Min_Number (Value : F64x4) return F64 is
     (Selected.Reduce_Min_Number (Value));
   function Reduce_Max_Number (Value : F64x4) return F64 is
     (Selected.Reduce_Max_Number (Value));
end Flyology_SIMD.Wide.Float_Reduce_Mechanism;
