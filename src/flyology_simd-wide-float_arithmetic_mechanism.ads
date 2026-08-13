private package Flyology_SIMD.Wide.Float_Arithmetic_Mechanism
  with Preelaborate
is
   --  Target-selected Wide floating-point arithmetic.

   function Add (Left, Right : F32x8) return F32x8
     with Inline_Always;
   --  Apply Add independently to corresponding lanes.
   --  @param Left The left input lanes.
   --  @param Right The right input lanes.
   --  @return The lane-wise floating-point results.
   function Subtract (Left, Right : F32x8) return F32x8
     with Inline_Always;
   --  Apply Subtract independently to corresponding lanes.
   --  @param Left The left input lanes.
   --  @param Right The right input lanes.
   --  @return The lane-wise floating-point results.
   function Multiply (Left, Right : F32x8) return F32x8
     with Inline_Always;
   --  Apply Multiply independently to corresponding lanes.
   --  @param Left The left input lanes.
   --  @param Right The right input lanes.
   --  @return The lane-wise floating-point results.
   function Divide (Left, Right : F32x8) return F32x8
     with Inline_Always;
   --  Apply Divide independently to corresponding lanes.
   --  @param Left The left input lanes.
   --  @param Right The right input lanes.
   --  @return The lane-wise floating-point results.
   function Min_Number (Left, Right : F32x8) return F32x8
     with Inline_Always;
   --  Apply Min_Number independently to corresponding lanes.
   --  @param Left The left input lanes.
   --  @param Right The right input lanes.
   --  @return The lane-wise floating-point results.
   function Max_Number (Left, Right : F32x8) return F32x8
     with Inline_Always;
   --  Apply Max_Number independently to corresponding lanes.
   --  @param Left The left input lanes.
   --  @param Right The right input lanes.
   --  @return The lane-wise floating-point results.
   function Add (Left, Right : F64x4) return F64x4
     with Inline_Always;
   --  Apply Add independently to corresponding lanes.
   --  @param Left The left input lanes.
   --  @param Right The right input lanes.
   --  @return The lane-wise floating-point results.
   function Subtract (Left, Right : F64x4) return F64x4
     with Inline_Always;
   --  Apply Subtract independently to corresponding lanes.
   --  @param Left The left input lanes.
   --  @param Right The right input lanes.
   --  @return The lane-wise floating-point results.
   function Multiply (Left, Right : F64x4) return F64x4
     with Inline_Always;
   --  Apply Multiply independently to corresponding lanes.
   --  @param Left The left input lanes.
   --  @param Right The right input lanes.
   --  @return The lane-wise floating-point results.
   function Divide (Left, Right : F64x4) return F64x4
     with Inline_Always;
   --  Apply Divide independently to corresponding lanes.
   --  @param Left The left input lanes.
   --  @param Right The right input lanes.
   --  @return The lane-wise floating-point results.
   function Min_Number (Left, Right : F64x4) return F64x4
     with Inline_Always;
   --  Apply Min_Number independently to corresponding lanes.
   --  @param Left The left input lanes.
   --  @param Right The right input lanes.
   --  @return The lane-wise floating-point results.
   function Max_Number (Left, Right : F64x4) return F64x4
     with Inline_Always;
   --  Apply Max_Number independently to corresponding lanes.
   --  @param Left The left input lanes.
   --  @param Right The right input lanes.
   --  @return The lane-wise floating-point results.
end Flyology_SIMD.Wide.Float_Arithmetic_Mechanism;
