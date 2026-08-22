package body Flyology_SIMD.Algorithms.Generic_Floating is
   procedure Scale (Data : in out F32_Array; Factor : F32) is
      Start         : Natural := Data'First;
      Factor_Vector : constant F32x4 := Backend_F32_Splat (Factor);
   begin
      while Start <= Data'Last loop
         declare
            Remaining : constant Natural := Data'Last - Start + 1;
            Count     : constant Lane_Count_32x4 := Lane_Count_32x4'Min (4, Remaining);
         begin
            Backend_F32_Store_Partial
              (Data,
               Start,
               Count,
               Backend_F32_Multiply (Backend_F32_Load_Partial (Data, Start, Count), Factor_Vector));
            exit when Count = Remaining;
            Start := Start + Count;
         end;
      end loop;
   end Scale;

   procedure Scale (Data : in out F64_Array; Factor : F64) is
      Start         : Natural := Data'First;
      Factor_Vector : constant F64x2 := Backend_F64_Splat (Factor);
   begin
      while Start <= Data'Last loop
         declare
            Remaining : constant Natural := Data'Last - Start + 1;
            Count     : constant Lane_Count_64x2 := Lane_Count_64x2'Min (2, Remaining);
         begin
            Backend_F64_Store_Partial
              (Data,
               Start,
               Count,
               Backend_F64_Multiply (Backend_F64_Load_Partial (Data, Start, Count), Factor_Vector));
            exit when Count = Remaining;
            Start := Start + Count;
         end;
      end loop;
   end Scale;

   procedure Clamp (Data : in out F32_Array; Low, High : F32) is
      Start       : Natural := Data'First;
      Low_Vector  : constant F32x4 := Backend_F32_Splat (Low);
      High_Vector : constant F32x4 := Backend_F32_Splat (High);
   begin
      while Start <= Data'Last loop
         declare
            Remaining : constant Natural := Data'Last - Start + 1;
            Count     : constant Lane_Count_32x4 := Lane_Count_32x4'Min (4, Remaining);
         begin
            Backend_F32_Store_Partial
              (Data,
               Start,
               Count,
               Backend_F32_Min_Number
                 (Backend_F32_Max_Number (Backend_F32_Load_Partial (Data, Start, Count), Low_Vector),
                  High_Vector));
            exit when Count = Remaining;
            Start := Start + Count;
         end;
      end loop;
   end Clamp;

   procedure Clamp (Data : in out F64_Array; Low, High : F64) is
      Start       : Natural := Data'First;
      Low_Vector  : constant F64x2 := Backend_F64_Splat (Low);
      High_Vector : constant F64x2 := Backend_F64_Splat (High);
   begin
      while Start <= Data'Last loop
         declare
            Remaining : constant Natural := Data'Last - Start + 1;
            Count     : constant Lane_Count_64x2 := Lane_Count_64x2'Min (2, Remaining);
         begin
            Backend_F64_Store_Partial
              (Data,
               Start,
               Count,
               Backend_F64_Min_Number
                 (Backend_F64_Max_Number (Backend_F64_Load_Partial (Data, Start, Count), Low_Vector),
                  High_Vector));
            exit when Count = Remaining;
            Start := Start + Count;
         end;
      end loop;
   end Clamp;

   procedure AXPY (Y : in out F32_Array; A : F32; X : F32_Array) is
      Start    : Natural := Y'First;
      A_Vector : constant F32x4 := Backend_F32_Splat (A);
   begin
      while Start <= Y'Last loop
         declare
            Remaining : constant Natural := Y'Last - Start + 1;
            Count     : constant Lane_Count_32x4 := Lane_Count_32x4'Min (4, Remaining);
         begin
            Backend_F32_Store_Partial
              (Y,
               Start,
               Count,
               Backend_F32_Add
                 (Backend_F32_Multiply (A_Vector, Backend_F32_Load_Partial (X, Start, Count)),
                  Backend_F32_Load_Partial (Y, Start, Count)));
            exit when Count = Remaining;
            Start := Start + Count;
         end;
      end loop;
   end AXPY;

   procedure AXPY (Y : in out F64_Array; A : F64; X : F64_Array) is
      Start    : Natural := Y'First;
      A_Vector : constant F64x2 := Backend_F64_Splat (A);
   begin
      while Start <= Y'Last loop
         declare
            Remaining : constant Natural := Y'Last - Start + 1;
            Count     : constant Lane_Count_64x2 := Lane_Count_64x2'Min (2, Remaining);
         begin
            Backend_F64_Store_Partial
              (Y,
               Start,
               Count,
               Backend_F64_Add
                 (Backend_F64_Multiply (A_Vector, Backend_F64_Load_Partial (X, Start, Count)),
                  Backend_F64_Load_Partial (Y, Start, Count)));
            exit when Count = Remaining;
            Start := Start + Count;
         end;
      end loop;
   end AXPY;

   function Sum (Data : F32_Array) return F32 is
      Start       : Natural := Data'First;
      Accumulator : F32x4 := Backend_F32_Zero;
   begin
      while Start <= Data'Last loop
         declare
            Remaining : constant Natural := Data'Last - Start + 1;
            Count     : constant Lane_Count_32x4 := Lane_Count_32x4'Min (4, Remaining);
         begin
            Accumulator := Backend_F32_Add (Accumulator, Backend_F32_Load_Partial (Data, Start, Count));
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
            Count     : constant Lane_Count_64x2 := Lane_Count_64x2'Min (2, Remaining);
         begin
            Accumulator := Backend_F64_Add (Accumulator, Backend_F64_Load_Partial (Data, Start, Count));
            exit when Count = Remaining;
            Start := Start + Count;
         end;
      end loop;

      return Backend_F64_Reduce_Add (Accumulator);
   end Sum;

   function Min_Number (Data : F32_Array) return F32 is
      Start  : Natural := Data'First;
      Result : F32;
   begin
      if Data'Length >= 4 then
         declare
            Accumulator : F32x4 := Backend_F32_Load_Partial (Data, Start, 4);
         begin
            Start := Start + 4;
            while Start <= Data'Last and then Data'Last - Start + 1 >= 4 loop
               Accumulator := Backend_F32_Min_Number (Accumulator, Backend_F32_Load_Partial (Data, Start, 4));
               Start := Start + 4;
            end loop;
            Result := Backend_F32_Reduce_Min_Number (Accumulator);
         end;
      else
         Result := Data (Start);
         Start := Start + 1;
      end if;
      while Start <= Data'Last loop
         Result :=
           Backend_F32_Extract
             (Backend_F32_Min_Number (Backend_F32_Splat (Result), Backend_F32_Splat (Data (Start))), 0);
         Start := Start + 1;
      end loop;
      return Result;
   end Min_Number;

   function Max_Number (Data : F32_Array) return F32 is
      Start  : Natural := Data'First;
      Result : F32;
   begin
      if Data'Length >= 4 then
         declare
            Accumulator : F32x4 := Backend_F32_Load_Partial (Data, Start, 4);
         begin
            Start := Start + 4;
            while Start <= Data'Last and then Data'Last - Start + 1 >= 4 loop
               Accumulator := Backend_F32_Max_Number (Accumulator, Backend_F32_Load_Partial (Data, Start, 4));
               Start := Start + 4;
            end loop;
            Result := Backend_F32_Reduce_Max_Number (Accumulator);
         end;
      else
         Result := Data (Start);
         Start := Start + 1;
      end if;
      while Start <= Data'Last loop
         Result :=
           Backend_F32_Extract
             (Backend_F32_Max_Number (Backend_F32_Splat (Result), Backend_F32_Splat (Data (Start))), 0);
         Start := Start + 1;
      end loop;
      return Result;
   end Max_Number;

   function Min_Number (Data : F64_Array) return F64 is
      Start  : Natural := Data'First;
      Result : F64;
   begin
      if Data'Length >= 2 then
         declare
            Accumulator : F64x2 := Backend_F64_Load_Partial (Data, Start, 2);
         begin
            Start := Start + 2;
            while Start <= Data'Last and then Data'Last - Start + 1 >= 2 loop
               Accumulator := Backend_F64_Min_Number (Accumulator, Backend_F64_Load_Partial (Data, Start, 2));
               Start := Start + 2;
            end loop;
            Result := Backend_F64_Reduce_Min_Number (Accumulator);
         end;
      else
         Result := Data (Start);
         Start := Start + 1;
      end if;
      while Start <= Data'Last loop
         Result :=
           Backend_F64_Extract
             (Backend_F64_Min_Number (Backend_F64_Splat (Result), Backend_F64_Splat (Data (Start))), 0);
         Start := Start + 1;
      end loop;
      return Result;
   end Min_Number;

   function Max_Number (Data : F64_Array) return F64 is
      Start  : Natural := Data'First;
      Result : F64;
   begin
      if Data'Length >= 2 then
         declare
            Accumulator : F64x2 := Backend_F64_Load_Partial (Data, Start, 2);
         begin
            Start := Start + 2;
            while Start <= Data'Last and then Data'Last - Start + 1 >= 2 loop
               Accumulator := Backend_F64_Max_Number (Accumulator, Backend_F64_Load_Partial (Data, Start, 2));
               Start := Start + 2;
            end loop;
            Result := Backend_F64_Reduce_Max_Number (Accumulator);
         end;
      else
         Result := Data (Start);
         Start := Start + 1;
      end if;
      while Start <= Data'Last loop
         Result :=
           Backend_F64_Extract
             (Backend_F64_Max_Number (Backend_F64_Splat (Result), Backend_F64_Splat (Data (Start))), 0);
         Start := Start + 1;
      end loop;
      return Result;
   end Max_Number;

   function Dot_Product (Left, Right : F32_Array) return F32 is
      Start       : Natural := Left'First;
      Accumulator : F32x4 := Backend_F32_Zero;
   begin
      while Start <= Left'Last loop
         declare
            Remaining   : constant Natural := Left'Last - Start + 1;
            Count       : constant Lane_Count_32x4 := Lane_Count_32x4'Min (4, Remaining);
            Left_Block  : constant F32x4 := Backend_F32_Load_Partial (Left, Start, Count);
            Right_Block : constant F32x4 := Backend_F32_Load_Partial (Right, Start, Count);
         begin
            Accumulator := Backend_F32_Add (Accumulator, Backend_F32_Multiply (Left_Block, Right_Block));
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
            Remaining   : constant Natural := Left'Last - Start + 1;
            Count       : constant Lane_Count_64x2 := Lane_Count_64x2'Min (2, Remaining);
            Left_Block  : constant F64x2 := Backend_F64_Load_Partial (Left, Start, Count);
            Right_Block : constant F64x2 := Backend_F64_Load_Partial (Right, Start, Count);
         begin
            Accumulator := Backend_F64_Add (Accumulator, Backend_F64_Multiply (Left_Block, Right_Block));
            exit when Count = Remaining;
            Start := Start + Count;
         end;
      end loop;

      return Backend_F64_Reduce_Add (Accumulator);
   end Dot_Product;
end Flyology_SIMD.Algorithms.Generic_Floating;
