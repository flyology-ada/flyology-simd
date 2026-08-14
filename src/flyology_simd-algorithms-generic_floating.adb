package body Flyology_SIMD.Algorithms.Generic_Floating is
   function Sum (Data : F32_Array) return F32 is
      Start       : Natural := Data'First;
      Accumulator : F32x4 := Backend_F32_Zero;
   begin
      while Start <= Data'Last loop
         declare
            Remaining : constant Natural := Data'Last - Start + 1;
            Count     : constant Lane_Count_32x4 :=
              Lane_Count_32x4'Min (4, Remaining);
         begin
            Accumulator := Backend_F32_Add
              (Accumulator,
               Backend_F32_Load_Partial (Data, Start, Count));
            exit when Count = Remaining;
            Start := Start + Count;
         end;
      end loop;

      return Backend_F32_Reduce_Add (Accumulator);
   end Sum;

   function Sum (Data : F64_Array) return F64 is
      Start       : Natural := Data'First;
      Accumulator : F64x2 := Backend_F64_Zero;
   begin
      while Start <= Data'Last loop
         declare
            Remaining : constant Natural := Data'Last - Start + 1;
            Count     : constant Lane_Count_64x2 :=
              Lane_Count_64x2'Min (2, Remaining);
         begin
            Accumulator := Backend_F64_Add
              (Accumulator,
               Backend_F64_Load_Partial (Data, Start, Count));
            exit when Count = Remaining;
            Start := Start + Count;
         end;
      end loop;

      return Backend_F64_Reduce_Add (Accumulator);
   end Sum;

   function Dot_Product (Left, Right : F32_Array) return F32 is
      Start       : Natural := Left'First;
      Accumulator : F32x4 := Backend_F32_Zero;
   begin
      while Start <= Left'Last loop
         declare
            Remaining : constant Natural := Left'Last - Start + 1;
            Count     : constant Lane_Count_32x4 :=
              Lane_Count_32x4'Min (4, Remaining);
            Left_Block : constant F32x4 :=
              Backend_F32_Load_Partial (Left, Start, Count);
            Right_Block : constant F32x4 :=
              Backend_F32_Load_Partial (Right, Start, Count);
         begin
            Accumulator := Backend_F32_Add
              (Accumulator,
               Backend_F32_Multiply (Left_Block, Right_Block));
            exit when Count = Remaining;
            Start := Start + Count;
         end;
      end loop;

      return Backend_F32_Reduce_Add (Accumulator);
   end Dot_Product;

   function Dot_Product (Left, Right : F64_Array) return F64 is
      Start       : Natural := Left'First;
      Accumulator : F64x2 := Backend_F64_Zero;
   begin
      while Start <= Left'Last loop
         declare
            Remaining : constant Natural := Left'Last - Start + 1;
            Count     : constant Lane_Count_64x2 :=
              Lane_Count_64x2'Min (2, Remaining);
            Left_Block : constant F64x2 :=
              Backend_F64_Load_Partial (Left, Start, Count);
            Right_Block : constant F64x2 :=
              Backend_F64_Load_Partial (Right, Start, Count);
         begin
            Accumulator := Backend_F64_Add
              (Accumulator,
               Backend_F64_Multiply (Left_Block, Right_Block));
            exit when Count = Remaining;
            Start := Start + Count;
         end;
      end loop;

      return Backend_F64_Reduce_Add (Accumulator);
   end Dot_Product;
end Flyology_SIMD.Algorithms.Generic_Floating;
