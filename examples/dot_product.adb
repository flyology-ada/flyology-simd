with Ada.Text_IO;
with Flyology_SIMD;
with Flyology_SIMD.Algorithms.Native_Floating;
with Flyology_SIMD.Algorithms.Runtime;
with Flyology_SIMD.Algorithms.Scalar_Floating;

procedure Dot_Product is
   use Ada.Text_IO;
   use Flyology_SIMD;
   use type Flyology_SIMD.F32;

   function Ordinary_Dot_Product
     (Left, Right : F32_Array) return F32
     with Pre => Left'First = Right'First and Left'Last = Right'Last
   is
      Result : F32 := 0.0;
   begin
      for Index in Left'Range loop
         Result := Result + Left (Index) * Right (Index);
      end loop;
      return Result;
   end Ordinary_Dot_Product;

   Left : constant F32_Array := [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0];
   Right : constant F32_Array := [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5];

   Ordinary : constant F32 := Ordinary_Dot_Product (Left, Right);
   Scalar   : constant F32 :=
     Algorithms.Scalar_Floating.Dot_Product (Left, Right);
   Native_Result : constant F32 :=
     Algorithms.Native_Floating.Dot_Product (Left, Right);
   Runtime_Result : constant F32 :=
     Algorithms.Runtime.Dot_Product (Left, Right);
begin
   pragma Assert (Ordinary = 70.0);
   pragma Assert (Scalar = Ordinary);
   pragma Assert (Native_Result = Ordinary);
   pragma Assert (Runtime_Result = Ordinary);

   Put_Line ("ordinary Ada dot:" & F32'Image (Ordinary));
   Put_Line ("scalar backend dot:" & F32'Image (Scalar));
   Put_Line ("native backend dot:" & F32'Image (Native_Result));
   Put_Line ("runtime-dispatched dot:" & F32'Image (Runtime_Result));
end Dot_Product;
