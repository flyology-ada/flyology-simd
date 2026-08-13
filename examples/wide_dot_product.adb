with Ada.Text_IO;
with Flyology_SIMD;
with Flyology_SIMD.Wide;
with Flyology_SIMD.Wide.Native;

procedure Wide_Dot_Product is
   use Ada.Text_IO;
   use Flyology_SIMD;
   use type Flyology_SIMD.F32;
   package Wide renames Flyology_SIMD.Wide;
   package Native renames Flyology_SIMD.Wide.Native;
   use type Wide.Lane_Values_F32x8;

   Samples : constant F32_Array :=
     [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0];
   Weights : constant F32_Array :=
     [2.0, 3.0, 5.0, 7.0, 11.0, 13.0, 17.0, 19.0];

   Sample_Vector : constant Wide.F32x8 :=
     Native.Load_Unaligned (Samples, Samples'First);
   Weight_Vector : constant Wide.F32x8 :=
     Native.Load_Unaligned (Weights, Weights'First);
   Products : constant Wide.F32x8 :=
     Native.Multiply (Sample_Vector, Weight_Vector);
   Product_Lanes : constant Wide.Lane_Values_F32x8 :=
     Native.To_Lanes (Products);
   Result : constant F32 := Native.Reduce_Add (Products);
   Smallest_Product : constant F32 := Native.Reduce_Min_Number (Products);
   Largest_Product : constant F32 := Native.Reduce_Max_Number (Products);

   Order_Sensitive : constant Wide.F32x8 := Native.From_Lanes
     ([1.0E20, 1.0, 0.0, 0.0, -1.0E20, 1.0, 0.0, 0.0]);
   Ordered_Result : constant F32 := Native.Reduce_Add (Order_Sensitive);
begin
   pragma Assert
     (Product_Lanes = [2.0, 6.0, 15.0, 28.0, 55.0, 78.0, 119.0, 152.0]);
   pragma Assert (Result = 455.0);
   pragma Assert (Smallest_Product = 2.0);
   pragma Assert (Largest_Product = 152.0);
   pragma Assert (Ordered_Result = 1.0);

   Put ("products:");
   for Value of Product_Lanes loop
      Put (F32'Image (Value));
   end loop;
   New_Line;
   Put_Line ("weighted sum:" & F32'Image (Result));
   Put_Line
     ("product range:" & F32'Image (Smallest_Product) &
      " .." & F32'Image (Largest_Product));
   Put_Line ("order-sensitive sum:" & F32'Image (Ordered_Result));
end Wide_Dot_Product;
