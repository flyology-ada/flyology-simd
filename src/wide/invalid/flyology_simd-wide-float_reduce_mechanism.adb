package body Flyology_SIMD.Wide.Float_Reduce_Mechanism is
   function Reduce_Add (Value : F32x8) return F32 is
     (Flyology_SIMD.Wide.Reduce_Add (Value));
   function Reduce_Min_Number (Value : F32x8) return F32 is
     (Flyology_SIMD.Wide.Reduce_Min_Number (Value));
   function Reduce_Max_Number (Value : F32x8) return F32 is
     (Flyology_SIMD.Wide.Reduce_Max_Number (Value));
   function Reduce_Add (Value : F64x4) return F64 is
     (Flyology_SIMD.Wide.Reduce_Add (Value));
   function Reduce_Min_Number (Value : F64x4) return F64 is
     (Flyology_SIMD.Wide.Reduce_Min_Number (Value));
   function Reduce_Max_Number (Value : F64x4) return F64 is
     (Flyology_SIMD.Wide.Reduce_Max_Number (Value));
end Flyology_SIMD.Wide.Float_Reduce_Mechanism;
