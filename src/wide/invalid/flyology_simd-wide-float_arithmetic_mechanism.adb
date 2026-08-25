with Flyology_SIMD.Backends.Native;

package body Flyology_SIMD.Wide.Float_Arithmetic_Mechanism
  with SPARK_Mode => On
is
   function Add (Left, Right : F32x8) return F32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Add
                (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Add
                (Left.High, Right.High)));
   function Subtract (Left, Right : F32x8) return F32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Subtract
                (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Subtract
                (Left.High, Right.High)));
   function Multiply (Left, Right : F32x8) return F32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Multiply
                (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Multiply
                (Left.High, Right.High)));
   function Divide (Left, Right : F32x8) return F32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Divide
                (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Divide
                (Left.High, Right.High)));
   function Min_Number (Left, Right : F32x8) return F32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Min_Number
                (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Min_Number
                (Left.High, Right.High)));
   function Max_Number (Left, Right : F32x8) return F32x8 is
     ((Low => Flyology_SIMD.Backends.Native.Max_Number
                (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Max_Number
                (Left.High, Right.High)));
   function Add (Left, Right : F64x4) return F64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Add
                (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Add
                (Left.High, Right.High)));
   function Subtract (Left, Right : F64x4) return F64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Subtract
                (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Subtract
                (Left.High, Right.High)));
   function Multiply (Left, Right : F64x4) return F64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Multiply
                (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Multiply
                (Left.High, Right.High)));
   function Divide (Left, Right : F64x4) return F64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Divide
                (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Divide
                (Left.High, Right.High)));
   function Min_Number (Left, Right : F64x4) return F64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Min_Number
                (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Min_Number
                (Left.High, Right.High)));
   function Max_Number (Left, Right : F64x4) return F64x4 is
     ((Low => Flyology_SIMD.Backends.Native.Max_Number
                (Left.Low, Right.Low),
       High => Flyology_SIMD.Backends.Native.Max_Number
                (Left.High, Right.High)));
end Flyology_SIMD.Wide.Float_Arithmetic_Mechanism;
