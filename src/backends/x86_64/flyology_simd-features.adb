with Interfaces;
with System.Machine_Code;
with Flyology_SIMD.Configuration;

package body Flyology_SIMD.Features is
   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_64;
   use System.Machine_Code;

   procedure CPUID
     (Leaf, Subleaf : Interfaces.Unsigned_32;
      EAX, EBX, ECX, EDX : out Interfaces.Unsigned_32) is
   begin
      Asm
        ("cpuid",
         Outputs =>
           [Interfaces.Unsigned_32'Asm_Output ("=a", EAX),
            Interfaces.Unsigned_32'Asm_Output ("=b", EBX),
            Interfaces.Unsigned_32'Asm_Output ("=c", ECX),
            Interfaces.Unsigned_32'Asm_Output ("=d", EDX)],
         Inputs =>
           [Interfaces.Unsigned_32'Asm_Input ("0", Leaf),
            Interfaces.Unsigned_32'Asm_Input ("2", Subleaf)],
         Volatile => True);
   end CPUID;

   function XCR0 return Interfaces.Unsigned_64 is
      Low, High : Interfaces.Unsigned_32;
   begin
      Asm
        ("xgetbv",
         Outputs =>
           [Interfaces.Unsigned_32'Asm_Output ("=a", Low),
            Interfaces.Unsigned_32'Asm_Output ("=d", High)],
         Inputs => Interfaces.Unsigned_32'Asm_Input ("c", 0),
         Volatile => True);
      return Interfaces.Shift_Left (Interfaces.Unsigned_64 (High), 32)
        or Interfaces.Unsigned_64 (Low);
   end XCR0;

   function Host_Has_AVX2 return Boolean is
      EAX, EBX, ECX, EDX : Interfaces.Unsigned_32;
      Maximum : Interfaces.Unsigned_32;
      OSXSAVE : constant Interfaces.Unsigned_32 := 2 ** 27;
      AVX     : constant Interfaces.Unsigned_32 := 2 ** 28;
      AVX2_Bit : constant Interfaces.Unsigned_32 := 2 ** 5;
   begin
      CPUID (0, 0, EAX, EBX, ECX, EDX);
      Maximum := EAX;
      if Maximum < 7 then
         return False;
      end if;
      CPUID (1, 0, EAX, EBX, ECX, EDX);
      if (ECX and (OSXSAVE or AVX)) /= (OSXSAVE or AVX)
        or else (XCR0 and 6) /= 6
      then
         return False;
      end if;
      CPUID (7, 0, EAX, EBX, ECX, EDX);
      return (EBX and AVX2_Bit) /= 0;
   end Host_Has_AVX2;

   function Compiled (Backend : Backend_Kind) return Boolean is
     (case Backend is
         when Scalar | SSE2 => True,
         when AVX2 => Configuration.AVX2_Compiled,
         when NEON => False);

   function Available (Backend : Backend_Kind) return Boolean is
     (case Backend is
         when Scalar | SSE2 => True,
         when AVX2 => Configuration.AVX2_Compiled and then Host_Has_AVX2,
         when NEON => False);

   function Best_Available return Backend_Kind is
     (if Available (AVX2) then AVX2 else SSE2);

   procedure Require (Backend : Backend_Kind) is
   begin
      if not Available (Backend) then
         raise Backend_Unavailable with Name (Backend) & " is not available";
      end if;
   end Require;

   function Name (Backend : Backend_Kind) return String is
     (case Backend is
         when Scalar => "scalar", when NEON => "neon",
         when SSE2 => "sse2", when AVX2 => "avx2");
   function Architecture_Name return String is ("x86_64");
end Flyology_SIMD.Features;
