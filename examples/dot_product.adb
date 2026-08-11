with Ada.Text_IO;
with Flyology_SIMD;
with Flyology_SIMD.Backends.Native;

procedure Dot_Product is
   use Ada.Text_IO;
   use Flyology_SIMD;
   use type Flyology_SIMD.F32;
   package Native renames Flyology_SIMD.Backends.Native;

   generic
      with function Vector_Zero return F32x4;
      with function Vector_Load_Partial
        (Data  : F32_Array;
         Start : Natural;
         Count : Lane_Count_32x4) return F32x4;
      with function Vector_Multiply
        (Left, Right : F32x4) return F32x4;
      with function Vector_Add
        (Left, Right : F32x4) return F32x4;
      with function Vector_Reduce_Add (Value : F32x4) return F32;
   function Generic_Dot_Product
     (Left, Right : F32_Array) return F32
     with Pre => Left'First = Right'First and Left'Last = Right'Last;

   function Generic_Dot_Product
     (Left, Right : F32_Array) return F32
   is
      Start       : Natural := Left'First;
      Accumulator : F32x4 := Vector_Zero;
   begin
      while Start <= Left'Last loop
         declare
            Remaining : constant Natural := Left'Last - Start + 1;
            Count     : constant Lane_Count_32x4 :=
              Lane_Count_32x4'Min (4, Remaining);
            Left_Block : constant F32x4 :=
              Vector_Load_Partial (Left, Start, Count);
            Right_Block : constant F32x4 :=
              Vector_Load_Partial (Right, Start, Count);
         begin
            Accumulator := Vector_Add
              (Accumulator, Vector_Multiply (Left_Block, Right_Block));
            exit when Count = Remaining;
            Start := Start + Count;
         end;
      end loop;

      return Vector_Reduce_Add (Accumulator);
   end Generic_Dot_Product;

   function Scalar_Dot_Product is new Generic_Dot_Product
     (Vector_Zero         => Flyology_SIMD.Zero,
      Vector_Load_Partial => Flyology_SIMD.Load_Partial,
      Vector_Multiply     => Flyology_SIMD.Multiply,
      Vector_Add          => Flyology_SIMD.Add,
      Vector_Reduce_Add   => Flyology_SIMD.Reduce_Add);

   function Native_Dot_Product is new Generic_Dot_Product
     (Vector_Zero         => Native.Zero,
      Vector_Load_Partial => Native.Load_Partial,
      Vector_Multiply     => Native.Multiply,
      Vector_Add          => Native.Add,
      Vector_Reduce_Add   => Native.Reduce_Add);

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
   Scalar   : constant F32 := Scalar_Dot_Product (Left, Right);
   Native_Result : constant F32 := Native_Dot_Product (Left, Right);
begin
   pragma Assert (Ordinary = 70.0);
   pragma Assert (Scalar = Ordinary);
   pragma Assert (Native_Result = Ordinary);

   Put_Line ("ordinary Ada dot:" & F32'Image (Ordinary));
   Put_Line ("scalar backend dot:" & F32'Image (Scalar));
   Put_Line ("native backend dot:" & F32'Image (Native_Result));
end Dot_Product;
