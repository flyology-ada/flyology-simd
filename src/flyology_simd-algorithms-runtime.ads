with Flyology_SIMD.Features;

--  Complete-array and complete-buffer algorithms with one coarse runtime
--  backend selection.
package Flyology_SIMD.Algorithms.Runtime is
   procedure Scale
     (Data : in out F32_Array;
      Factor : F32;
      Backend : Features.Backend_Kind := Features.Best_Available);
   --  Multiply every binary32 element by Factor after one runtime backend
   --  selection.
   --  @param Data The complete array to transform in place.
   --  @param Factor The scalar multiplier applied once to every element.
   --  @param Backend The compiled and available backend to use.
   procedure Scale
     (Data : in out F64_Array;
      Factor : F64;
      Backend : Features.Backend_Kind := Features.Best_Available);
   --  Multiply every binary64 element by Factor after one runtime backend
   --  selection.
   --  @param Data The complete array to transform in place.
   --  @param Factor The scalar multiplier applied once to every element.
   --  @param Backend The compiled and available backend to use.

   procedure Clamp
     (Data : in out F32_Array;
      Low, High : F32;
      Backend : Features.Backend_Kind := Features.Best_Available);
   --  Replace each element with Min_Number (Max_Number (Element, Low), High)
   --  after one runtime backend selection.
   --  @param Data The complete array to transform in place.
   --  @param Low The lower operand supplied to Max_Number.
   --  @param High The upper operand supplied to Min_Number.
   --  @param Backend The compiled and available backend to use.
   procedure Clamp
     (Data : in out F64_Array;
      Low, High : F64;
      Backend : Features.Backend_Kind := Features.Best_Available);
   --  Replace each element with Min_Number (Max_Number (Element, Low), High)
   --  after one runtime backend selection.
   --  @param Data The complete array to transform in place.
   --  @param Low The lower operand supplied to Max_Number.
   --  @param High The upper operand supplied to Min_Number.
   --  @param Backend The compiled and available backend to use.

   procedure AXPY
     (Y : in out F32_Array;
      A : F32;
      X : F32_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
     with Pre => Y'First = X'First and Y'Last = X'Last;
   --  Replace each Y element with A * X + Y after one runtime backend
   --  selection. Multiplication and addition are separate operations.
   --  @param Y The complete destination and addend array.
   --  @param A The scalar multiplier applied to X.
   --  @param X The complete source array with bounds matching Y.
   --  @param Backend The compiled and available backend to use.
   procedure AXPY
     (Y : in out F64_Array;
      A : F64;
      X : F64_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
     with Pre => Y'First = X'First and Y'Last = X'Last;
   --  Replace each Y element with A * X + Y after one runtime backend
   --  selection. Multiplication and addition are separate operations.
   --  @param Y The complete destination and addend array.
   --  @param A The scalar multiplier applied to X.
   --  @param X The complete source array with bounds matching Y.
   --  @param Backend The compiled and available backend to use.

   function Sum
     (Data : F32_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return F32;
   --  Add all binary32 elements after one runtime backend selection.
   --  Use the four-group accumulation order from Generic_Floating.Sum.
   --  @param Data The complete array to sum.
   --  @param Backend The compiled and available backend to use.
   --  @return The lane-grouped sum of all elements.
   function Sum
     (Data : F64_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return F64;
   --  Add all binary64 elements after one runtime backend selection.
   --  Use the two-group accumulation order from Generic_Floating.Sum.
   --  @param Data The complete array to sum.
   --  @param Backend The compiled and available backend to use.
   --  @return The lane-grouped sum of all elements.

   function Min_Number
     (Data : F32_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return F32
     with Pre => Data'Length > 0;
   --  Return the number minimum of a nonempty binary32 array after one
   --  runtime backend selection.
   --  @param Data The nonempty complete array to reduce.
   --  @param Backend The compiled and available backend to use.
   --  @return The minimum-number result.
   function Max_Number
     (Data : F32_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return F32
     with Pre => Data'Length > 0;
   --  Return the number maximum of a nonempty binary32 array after one
   --  runtime backend selection.
   --  @param Data The nonempty complete array to reduce.
   --  @param Backend The compiled and available backend to use.
   --  @return The maximum-number result.
   function Min_Number
     (Data : F64_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return F64
     with Pre => Data'Length > 0;
   --  Return the number minimum of a nonempty binary64 array after one
   --  runtime backend selection.
   --  @param Data The nonempty complete array to reduce.
   --  @param Backend The compiled and available backend to use.
   --  @return The minimum-number result.
   function Max_Number
     (Data : F64_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return F64
     with Pre => Data'Length > 0;
   --  Return the number maximum of a nonempty binary64 array after one
   --  runtime backend selection.
   --  @param Data The nonempty complete array to reduce.
   --  @param Backend The compiled and available backend to use.
   --  @return The maximum-number result.

   function Dot_Product
     (Left, Right : F32_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return F32
     with Pre => Left'First = Right'First and Left'Last = Right'Last;
   --  Multiply and add corresponding binary32 elements after one runtime
   --  backend selection.
   --  Use the four-group accumulation order from Generic_Floating.Dot_Product.
   --  @param Left The left complete array.
   --  @param Right The right complete array with matching bounds.
   --  @param Backend The compiled and available backend to use.
   --  @return The lane-grouped sum of corresponding products.
   function Dot_Product
     (Left, Right : F64_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return F64
     with Pre => Left'First = Right'First and Left'Last = Right'Last;
   --  Multiply and add corresponding binary64 elements after one runtime
   --  backend selection.
   --  Use the two-group accumulation order from Generic_Floating.Dot_Product.
   --  @param Left The left complete array.
   --  @param Right The right complete array with matching bounds.
   --  @param Backend The compiled and available backend to use.
   --  @return The lane-grouped sum of corresponding products.

   function Find_First_Difference
     (Left, Right : Byte_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return Search_Result
     with Pre => Left'First = Right'First and Left'Last = Right'Last;
   --  Find the first differing byte after one runtime backend selection.
   --  @param Left The left complete byte array.
   --  @param Right The right complete byte array with matching bounds.
   --  @param Backend The compiled and available backend to use.
   --  @return A found flag and the first differing Ada index.
   function Equal
     (Left, Right : Byte_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return Boolean
     with Pre => Left'First = Right'First and Left'Last = Right'Last;
   --  Compare two complete byte buffers after one runtime backend selection.
   --  @param Left The left complete byte array.
   --  @param Right The right complete byte array with matching bounds.
   --  @param Backend The compiled and available backend to use.
   --  @return True when every corresponding byte is equal.

   function Find_First
     (Data : Byte_Array;
      Needle : U8;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return Search_Result;
   --  Find one byte after one runtime backend selection.
   --  @param Data The complete byte array to search.
   --  @param Needle The byte to find.
   --  @param Backend The compiled and available backend to use.
   --  @return A found flag and the first matching Ada index.
   function Find_First_Of
     (Data : Byte_Array;
      Needles : Byte_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return Search_Result;
   --  Find the first byte equal to any member of a small set after one runtime
   --  backend selection. Empty inputs have no match and duplicates have no
   --  effect.
   --  @param Data The complete byte array to search.
   --  @param Needles The byte values that constitute the small set.
   --  @param Backend The compiled and available backend to use.
   --  @return A found flag and the first matching Ada index.
   function Count
     (Data : Byte_Array;
      Needle : U8;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return Natural;
   --  Count one byte after one runtime backend selection.
   --  @param Data The complete byte array to scan.
   --  @param Needle The byte to count.
   --  @param Backend The compiled and available backend to use.
   --  @return The number of matching elements.
   function Count_In_Range
     (Data : Byte_Array;
      Low, High : U8;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return Natural;
   --  Count bytes in an inclusive unsigned interval after one runtime backend
   --  selection. An inverted interval is empty.
   --  @param Data The complete byte array to scan.
   --  @param Low The inclusive lower byte bound.
   --  @param High The inclusive upper byte bound.
   --  @param Backend The compiled and available backend to use.
   --  @return The number of elements in the interval.
   procedure Add_Saturate
     (Data : in out Byte_Array;
      Value : U8;
      Backend : Features.Backend_Kind := Features.Best_Available);
   --  Add one byte to every element with unsigned saturation after one
   --  runtime backend selection.
   --  @param Data The complete byte buffer to transform in place.
   --  @param Value The unsigned byte addend broadcast to every element.
   --  @param Backend The compiled and available backend to use.
   function Is_ASCII
     (Data : Byte_Array;
      Backend : Features.Backend_Kind := Features.Best_Available)
      return Boolean;
   --  Validate ASCII after one runtime backend selection.
   --  @param Data The complete byte array to validate.
   --  @param Backend The compiled and available backend to use.
   --  @return True when every byte is less than 128.
end Flyology_SIMD.Algorithms.Runtime;
