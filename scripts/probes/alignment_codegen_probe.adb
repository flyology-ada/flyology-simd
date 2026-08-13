with Flyology_SIMD.Backends.Native;
with Flyology_SIMD.Wide.Native;

package body Alignment_Codegen_Probe is
   package Native renames Flyology_SIMD.Backends.Native;
   package Wide_Native renames Flyology_SIMD.Wide.Native;

   function I8_Aligned_16
     (Data : Flyology_SIMD.I8_Array; Start : Natural) return Boolean is
     (Native.Is_Aligned_16 (Data, Start));
   function U16_Aligned_16
     (Data : Flyology_SIMD.U16_Array; Start : Natural) return Boolean is
     (Native.Is_Aligned_16 (Data, Start));
   function I16_Aligned_16
     (Data : Flyology_SIMD.I16_Array; Start : Natural) return Boolean is
     (Native.Is_Aligned_16 (Data, Start));
   function U32_Aligned_16
     (Data : Flyology_SIMD.U32_Array; Start : Natural) return Boolean is
     (Native.Is_Aligned_16 (Data, Start));
   function I32_Aligned_16
     (Data : Flyology_SIMD.I32_Array; Start : Natural) return Boolean is
     (Native.Is_Aligned_16 (Data, Start));
   function U64_Aligned_16
     (Data : Flyology_SIMD.U64_Array; Start : Natural) return Boolean is
     (Native.Is_Aligned_16 (Data, Start));
   function I64_Aligned_16
     (Data : Flyology_SIMD.I64_Array; Start : Natural) return Boolean is
     (Native.Is_Aligned_16 (Data, Start));
   function F32_Aligned_16
     (Data : Flyology_SIMD.F32_Array; Start : Natural) return Boolean is
     (Native.Is_Aligned_16 (Data, Start));
   function F64_Aligned_16
     (Data : Flyology_SIMD.F64_Array; Start : Natural) return Boolean is
     (Native.Is_Aligned_16 (Data, Start));

   function U8_Aligned_32
     (Data : Flyology_SIMD.Byte_Array; Start : Natural) return Boolean is
     (Wide_Native.Is_Aligned_32 (Data, Start));
   function I8_Aligned_32
     (Data : Flyology_SIMD.I8_Array; Start : Natural) return Boolean is
     (Wide_Native.Is_Aligned_32 (Data, Start));
   function U16_Aligned_32
     (Data : Flyology_SIMD.U16_Array; Start : Natural) return Boolean is
     (Wide_Native.Is_Aligned_32 (Data, Start));
   function I16_Aligned_32
     (Data : Flyology_SIMD.I16_Array; Start : Natural) return Boolean is
     (Wide_Native.Is_Aligned_32 (Data, Start));
   function U32_Aligned_32
     (Data : Flyology_SIMD.U32_Array; Start : Natural) return Boolean is
     (Wide_Native.Is_Aligned_32 (Data, Start));
   function I32_Aligned_32
     (Data : Flyology_SIMD.I32_Array; Start : Natural) return Boolean is
     (Wide_Native.Is_Aligned_32 (Data, Start));
   function U64_Aligned_32
     (Data : Flyology_SIMD.U64_Array; Start : Natural) return Boolean is
     (Wide_Native.Is_Aligned_32 (Data, Start));
   function I64_Aligned_32
     (Data : Flyology_SIMD.I64_Array; Start : Natural) return Boolean is
     (Wide_Native.Is_Aligned_32 (Data, Start));
   function F32_Aligned_32
     (Data : Flyology_SIMD.F32_Array; Start : Natural) return Boolean is
     (Wide_Native.Is_Aligned_32 (Data, Start));
   function F64_Aligned_32
     (Data : Flyology_SIMD.F64_Array; Start : Natural) return Boolean is
     (Wide_Native.Is_Aligned_32 (Data, Start));
end Alignment_Codegen_Probe;
