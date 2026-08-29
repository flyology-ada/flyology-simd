package body Flyology_SIMD.Algorithms.Generic_Floating
  with SPARK_Mode => On
is
   subtype Buffer_Offset is Long_Long_Integer range 0 .. Long_Long_Integer (Natural'Last) + 1;

   function Length_Of (Data : F32_Array) return Buffer_Offset
   is (Buffer_Offset (Data'Length));

   function Length_Of (Data : F64_Array) return Buffer_Offset
   is (Buffer_Offset (Data'Length));

   function Index_At (Data : F32_Array; Offset : Buffer_Offset) return Natural
   with
     Pre  => Offset < Length_Of (Data),
     Post => Index_At'Result in Data'Range and then Index_At'Result - Data'First = Natural (Offset)
   is
   begin
      return Data'First + Natural (Offset);
   end Index_At;
   pragma Inline_Always (Index_At);

   function Index_At (Data : F64_Array; Offset : Buffer_Offset) return Natural
   with
     Pre  => Offset < Length_Of (Data),
     Post => Index_At'Result in Data'Range and then Index_At'Result - Data'First = Natural (Offset)
   is
   begin
      return Data'First + Natural (Offset);
   end Index_At;
   pragma Inline_Always (Index_At);

   function Block_Count_32 (Remaining : Buffer_Offset) return Lane_Count_32x4
   is (if Remaining >= 4 then 4 else Lane_Count_32x4 (Remaining))
   with
     Pre  => Remaining > 0,
     Post => Block_Count_32'Result > 0 and then Buffer_Offset (Block_Count_32'Result) <= Remaining;

   function Block_Count_64 (Remaining : Buffer_Offset) return Lane_Count_64x2
   is (if Remaining >= 2 then 2 else Lane_Count_64x2 (Remaining))
   with
     Pre  => Remaining > 0,
     Post => Block_Count_64'Result > 0 and then Buffer_Offset (Block_Count_64'Result) <= Remaining;

   procedure Scale (Data : in out F32_Array; Factor : F32) is
      Offset        : Buffer_Offset := 0;
      Factor_Vector : constant F32x4 := Backend_F32_Splat (Factor);
   begin
      while Offset < Length_Of (Data) loop
         pragma Loop_Invariant (Offset <= Length_Of (Data));
         pragma Loop_Variant (Decreases => Length_Of (Data) - Offset);
         declare
            Remaining : constant Buffer_Offset := Length_Of (Data) - Offset;
            Count     : constant Lane_Count_32x4 := Block_Count_32 (Remaining);
            Start     : constant Natural := Index_At (Data, Offset);
         begin
            Backend_F32_Store_Partial
              (Data,
               Start,
               Count,
               Backend_F32_Multiply (Backend_F32_Load_Partial (Data, Start, Count), Factor_Vector));
            Offset := Offset + Buffer_Offset (Count);
         end;
      end loop;
   end Scale;

   procedure Scale (Data : in out F64_Array; Factor : F64) is
      Offset        : Buffer_Offset := 0;
      Factor_Vector : constant F64x2 := Backend_F64_Splat (Factor);
   begin
      while Offset < Length_Of (Data) loop
         pragma Loop_Invariant (Offset <= Length_Of (Data));
         pragma Loop_Variant (Decreases => Length_Of (Data) - Offset);
         declare
            Remaining : constant Buffer_Offset := Length_Of (Data) - Offset;
            Count     : constant Lane_Count_64x2 := Block_Count_64 (Remaining);
            Start     : constant Natural := Index_At (Data, Offset);
         begin
            Backend_F64_Store_Partial
              (Data,
               Start,
               Count,
               Backend_F64_Multiply (Backend_F64_Load_Partial (Data, Start, Count), Factor_Vector));
            Offset := Offset + Buffer_Offset (Count);
         end;
      end loop;
   end Scale;

   procedure Clamp (Data : in out F32_Array; Low, High : F32) is
      Offset      : Buffer_Offset := 0;
      Low_Vector  : constant F32x4 := Backend_F32_Splat (Low);
      High_Vector : constant F32x4 := Backend_F32_Splat (High);
   begin
      while Offset < Length_Of (Data) loop
         pragma Loop_Invariant (Offset <= Length_Of (Data));
         pragma Loop_Variant (Decreases => Length_Of (Data) - Offset);
         declare
            Remaining : constant Buffer_Offset := Length_Of (Data) - Offset;
            Count     : constant Lane_Count_32x4 := Block_Count_32 (Remaining);
            Start     : constant Natural := Index_At (Data, Offset);
         begin
            Backend_F32_Store_Partial
              (Data,
               Start,
               Count,
               Backend_F32_Min_Number
                 (Backend_F32_Max_Number (Backend_F32_Load_Partial (Data, Start, Count), Low_Vector),
                  High_Vector));
            Offset := Offset + Buffer_Offset (Count);
         end;
      end loop;
   end Clamp;

   procedure Clamp (Data : in out F64_Array; Low, High : F64) is
      Offset      : Buffer_Offset := 0;
      Low_Vector  : constant F64x2 := Backend_F64_Splat (Low);
      High_Vector : constant F64x2 := Backend_F64_Splat (High);
   begin
      while Offset < Length_Of (Data) loop
         pragma Loop_Invariant (Offset <= Length_Of (Data));
         pragma Loop_Variant (Decreases => Length_Of (Data) - Offset);
         declare
            Remaining : constant Buffer_Offset := Length_Of (Data) - Offset;
            Count     : constant Lane_Count_64x2 := Block_Count_64 (Remaining);
            Start     : constant Natural := Index_At (Data, Offset);
         begin
            Backend_F64_Store_Partial
              (Data,
               Start,
               Count,
               Backend_F64_Min_Number
                 (Backend_F64_Max_Number (Backend_F64_Load_Partial (Data, Start, Count), Low_Vector),
                  High_Vector));
            Offset := Offset + Buffer_Offset (Count);
         end;
      end loop;
   end Clamp;

   procedure AXPY (Y : in out F32_Array; A : F32; X : F32_Array) is
      Offset   : Buffer_Offset := 0;
      A_Vector : constant F32x4 := Backend_F32_Splat (A);
   begin
      while Offset < Length_Of (Y) loop
         pragma Loop_Invariant (Offset <= Length_Of (Y));
         pragma Loop_Variant (Decreases => Length_Of (Y) - Offset);
         declare
            Remaining : constant Buffer_Offset := Length_Of (Y) - Offset;
            Count     : constant Lane_Count_32x4 := Block_Count_32 (Remaining);
            Y_Start   : constant Natural := Index_At (Y, Offset);
            X_Start   : constant Natural := Index_At (X, Offset);
         begin
            Backend_F32_Store_Partial
              (Y,
               Y_Start,
               Count,
               Backend_F32_Add
                 (Backend_F32_Multiply (A_Vector, Backend_F32_Load_Partial (X, X_Start, Count)),
                  Backend_F32_Load_Partial (Y, Y_Start, Count)));
            Offset := Offset + Buffer_Offset (Count);
         end;
      end loop;
   end AXPY;

   procedure AXPY (Y : in out F64_Array; A : F64; X : F64_Array) is
      Offset   : Buffer_Offset := 0;
      A_Vector : constant F64x2 := Backend_F64_Splat (A);
   begin
      while Offset < Length_Of (Y) loop
         pragma Loop_Invariant (Offset <= Length_Of (Y));
         pragma Loop_Variant (Decreases => Length_Of (Y) - Offset);
         declare
            Remaining : constant Buffer_Offset := Length_Of (Y) - Offset;
            Count     : constant Lane_Count_64x2 := Block_Count_64 (Remaining);
            Y_Start   : constant Natural := Index_At (Y, Offset);
            X_Start   : constant Natural := Index_At (X, Offset);
         begin
            Backend_F64_Store_Partial
              (Y,
               Y_Start,
               Count,
               Backend_F64_Add
                 (Backend_F64_Multiply (A_Vector, Backend_F64_Load_Partial (X, X_Start, Count)),
                  Backend_F64_Load_Partial (Y, Y_Start, Count)));
            Offset := Offset + Buffer_Offset (Count);
         end;
      end loop;
   end AXPY;

   function Sum (Data : F32_Array) return F32 is
      Offset      : Buffer_Offset := 0;
      Accumulator : F32x4 := Backend_F32_Zero;
   begin
      while Offset < Length_Of (Data) loop
         pragma Loop_Invariant (Offset <= Length_Of (Data));
         pragma Loop_Variant (Decreases => Length_Of (Data) - Offset);
         declare
            Remaining : constant Buffer_Offset := Length_Of (Data) - Offset;
            Count     : constant Lane_Count_32x4 := Block_Count_32 (Remaining);
            Start     : constant Natural := Index_At (Data, Offset);
         begin
            Accumulator := Backend_F32_Add (Accumulator, Backend_F32_Load_Partial (Data, Start, Count));
            Offset := Offset + Buffer_Offset (Count);
         end;
      end loop;

      return Backend_F32_Reduce_Add (Accumulator);
   end Sum;

   function Sum (Data : F64_Array) return F64 is
      Offset      : Buffer_Offset := 0;
      Accumulator : F64x2 := Backend_F64_Zero;
   begin
      while Offset < Length_Of (Data) loop
         pragma Loop_Invariant (Offset <= Length_Of (Data));
         pragma Loop_Variant (Decreases => Length_Of (Data) - Offset);
         declare
            Remaining : constant Buffer_Offset := Length_Of (Data) - Offset;
            Count     : constant Lane_Count_64x2 := Block_Count_64 (Remaining);
            Start     : constant Natural := Index_At (Data, Offset);
         begin
            Accumulator := Backend_F64_Add (Accumulator, Backend_F64_Load_Partial (Data, Start, Count));
            Offset := Offset + Buffer_Offset (Count);
         end;
      end loop;

      return Backend_F64_Reduce_Add (Accumulator);
   end Sum;

   function Min_Number (Data : F32_Array) return F32 is
      Offset : Buffer_Offset;
      Result : F32;
   begin
      if Length_Of (Data) >= 4 then
         declare
            Accumulator : F32x4 := Backend_F32_Load_Partial (Data, Index_At (Data, 0), 4);
         begin
            Offset := 4;
            while Length_Of (Data) - Offset >= 4 loop
               pragma Loop_Invariant (Offset <= Length_Of (Data));
               pragma Loop_Variant (Decreases => Length_Of (Data) - Offset);
               Accumulator :=
                 Backend_F32_Min_Number
                   (Accumulator, Backend_F32_Load_Partial (Data, Index_At (Data, Offset), 4));
               Offset := Offset + 4;
            end loop;
            Result := Backend_F32_Reduce_Min_Number (Accumulator);
         end;
      else
         Result := Data (Index_At (Data, 0));
         Offset := 1;
      end if;
      while Offset < Length_Of (Data) loop
         pragma Loop_Invariant (Offset <= Length_Of (Data));
         pragma Loop_Variant (Decreases => Length_Of (Data) - Offset);
         Result :=
           Backend_F32_Extract
             (Backend_F32_Min_Number
                (Backend_F32_Splat (Result), Backend_F32_Splat (Data (Index_At (Data, Offset)))),
              0);
         Offset := Offset + 1;
      end loop;
      return Result;
   end Min_Number;

   function Max_Number (Data : F32_Array) return F32 is
      Offset : Buffer_Offset;
      Result : F32;
   begin
      if Length_Of (Data) >= 4 then
         declare
            Accumulator : F32x4 := Backend_F32_Load_Partial (Data, Index_At (Data, 0), 4);
         begin
            Offset := 4;
            while Length_Of (Data) - Offset >= 4 loop
               pragma Loop_Invariant (Offset <= Length_Of (Data));
               pragma Loop_Variant (Decreases => Length_Of (Data) - Offset);
               Accumulator :=
                 Backend_F32_Max_Number
                   (Accumulator, Backend_F32_Load_Partial (Data, Index_At (Data, Offset), 4));
               Offset := Offset + 4;
            end loop;
            Result := Backend_F32_Reduce_Max_Number (Accumulator);
         end;
      else
         Result := Data (Index_At (Data, 0));
         Offset := 1;
      end if;
      while Offset < Length_Of (Data) loop
         pragma Loop_Invariant (Offset <= Length_Of (Data));
         pragma Loop_Variant (Decreases => Length_Of (Data) - Offset);
         Result :=
           Backend_F32_Extract
             (Backend_F32_Max_Number
                (Backend_F32_Splat (Result), Backend_F32_Splat (Data (Index_At (Data, Offset)))),
              0);
         Offset := Offset + 1;
      end loop;
      return Result;
   end Max_Number;

   function Min_Number (Data : F64_Array) return F64 is
      Offset : Buffer_Offset;
      Result : F64;
   begin
      if Length_Of (Data) >= 2 then
         declare
            Accumulator : F64x2 := Backend_F64_Load_Partial (Data, Index_At (Data, 0), 2);
         begin
            Offset := 2;
            while Length_Of (Data) - Offset >= 2 loop
               pragma Loop_Invariant (Offset <= Length_Of (Data));
               pragma Loop_Variant (Decreases => Length_Of (Data) - Offset);
               Accumulator :=
                 Backend_F64_Min_Number
                   (Accumulator, Backend_F64_Load_Partial (Data, Index_At (Data, Offset), 2));
               Offset := Offset + 2;
            end loop;
            Result := Backend_F64_Reduce_Min_Number (Accumulator);
         end;
      else
         Result := Data (Index_At (Data, 0));
         Offset := 1;
      end if;
      while Offset < Length_Of (Data) loop
         pragma Loop_Invariant (Offset <= Length_Of (Data));
         pragma Loop_Variant (Decreases => Length_Of (Data) - Offset);
         Result :=
           Backend_F64_Extract
             (Backend_F64_Min_Number
                (Backend_F64_Splat (Result), Backend_F64_Splat (Data (Index_At (Data, Offset)))),
              0);
         Offset := Offset + 1;
      end loop;
      return Result;
   end Min_Number;

   function Max_Number (Data : F64_Array) return F64 is
      Offset : Buffer_Offset;
      Result : F64;
   begin
      if Length_Of (Data) >= 2 then
         declare
            Accumulator : F64x2 := Backend_F64_Load_Partial (Data, Index_At (Data, 0), 2);
         begin
            Offset := 2;
            while Length_Of (Data) - Offset >= 2 loop
               pragma Loop_Invariant (Offset <= Length_Of (Data));
               pragma Loop_Variant (Decreases => Length_Of (Data) - Offset);
               Accumulator :=
                 Backend_F64_Max_Number
                   (Accumulator, Backend_F64_Load_Partial (Data, Index_At (Data, Offset), 2));
               Offset := Offset + 2;
            end loop;
            Result := Backend_F64_Reduce_Max_Number (Accumulator);
         end;
      else
         Result := Data (Index_At (Data, 0));
         Offset := 1;
      end if;
      while Offset < Length_Of (Data) loop
         pragma Loop_Invariant (Offset <= Length_Of (Data));
         pragma Loop_Variant (Decreases => Length_Of (Data) - Offset);
         Result :=
           Backend_F64_Extract
             (Backend_F64_Max_Number
                (Backend_F64_Splat (Result), Backend_F64_Splat (Data (Index_At (Data, Offset)))),
              0);
         Offset := Offset + 1;
      end loop;
      return Result;
   end Max_Number;

   function Dot_Product (Left, Right : F32_Array) return F32 is
      Offset      : Buffer_Offset := 0;
      Accumulator : F32x4 := Backend_F32_Zero;
   begin
      while Offset < Length_Of (Left) loop
         pragma Loop_Invariant (Offset <= Length_Of (Left));
         pragma Loop_Variant (Decreases => Length_Of (Left) - Offset);
         declare
            Remaining   : constant Buffer_Offset := Length_Of (Left) - Offset;
            Count       : constant Lane_Count_32x4 := Block_Count_32 (Remaining);
            Left_Start  : constant Natural := Index_At (Left, Offset);
            Right_Start : constant Natural := Index_At (Right, Offset);
            Left_Block  : constant F32x4 := Backend_F32_Load_Partial (Left, Left_Start, Count);
            Right_Block : constant F32x4 := Backend_F32_Load_Partial (Right, Right_Start, Count);
         begin
            Accumulator := Backend_F32_Add (Accumulator, Backend_F32_Multiply (Left_Block, Right_Block));
            Offset := Offset + Buffer_Offset (Count);
         end;
      end loop;

      return Backend_F32_Reduce_Add (Accumulator);
   end Dot_Product;

   function Dot_Product (Left, Right : F64_Array) return F64 is
      Offset      : Buffer_Offset := 0;
      Accumulator : F64x2 := Backend_F64_Zero;
   begin
      while Offset < Length_Of (Left) loop
         pragma Loop_Invariant (Offset <= Length_Of (Left));
         pragma Loop_Variant (Decreases => Length_Of (Left) - Offset);
         declare
            Remaining   : constant Buffer_Offset := Length_Of (Left) - Offset;
            Count       : constant Lane_Count_64x2 := Block_Count_64 (Remaining);
            Left_Start  : constant Natural := Index_At (Left, Offset);
            Right_Start : constant Natural := Index_At (Right, Offset);
            Left_Block  : constant F64x2 := Backend_F64_Load_Partial (Left, Left_Start, Count);
            Right_Block : constant F64x2 := Backend_F64_Load_Partial (Right, Right_Start, Count);
         begin
            Accumulator := Backend_F64_Add (Accumulator, Backend_F64_Multiply (Left_Block, Right_Block));
            Offset := Offset + Buffer_Offset (Count);
         end;
      end loop;

      return Backend_F64_Reduce_Add (Accumulator);
   end Dot_Product;
end Flyology_SIMD.Algorithms.Generic_Floating;
