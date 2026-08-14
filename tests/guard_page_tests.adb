with Ada.Text_IO;
with Interfaces.C;
with System;
with System.Storage_Elements;
with Flyology_SIMD;
with Flyology_SIMD.Algorithms;
with Flyology_SIMD.Algorithms.AVX2;
with Flyology_SIMD.Algorithms.Native;
with Flyology_SIMD.Algorithms.Runtime;
with Flyology_SIMD.Algorithms.Scalar;
with Flyology_SIMD.Backends.Native;
with Flyology_SIMD.Features;
with Flyology_SIMD.Wide;
with Flyology_SIMD.Wide.Native;

procedure Guard_Page_Tests is
   use Ada.Text_IO;
   use Flyology_SIMD;
   use System.Storage_Elements;
   use type Interfaces.C.int;
   use type Interfaces.Unsigned_8;
   use type Flyology_SIMD.Algorithms.Search_Result;
   use type Flyology_SIMD.F32;
   use type Flyology_SIMD.F64;
   use type System.Address;

   function Get_Page_Size return Interfaces.C.int
     with Import, Convention => C, External_Name => "getpagesize";

   function Posix_Memalign
     (Result    : access System.Address;
      Alignment : Interfaces.C.size_t;
      Size      : Interfaces.C.size_t) return Interfaces.C.int
     with Import, Convention => C, External_Name => "posix_memalign";

   function Mprotect
     (Address : System.Address;
      Length  : Interfaces.C.size_t;
      Protect : Interfaces.C.int) return Interfaces.C.int
     with Import, Convention => C, External_Name => "mprotect";

   procedure Free (Address : System.Address)
     with Import, Convention => C, External_Name => "free";

   Read_Write : constant Interfaces.C.int := 1 + 2;
   No_Access  : constant Interfaces.C.int := 0;
   Page_Size  : constant Natural := Natural (Get_Page_Size);
   Allocation : aliased System.Address := System.Null_Address;
   Failures   : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Failures := Failures + 1;
         Put_Line ("FAIL: " & Message);
      end if;
   end Check;

   function Add (Address : System.Address; Bytes : Natural)
     return System.Address is
     (Address + Storage_Offset (Bytes));

begin
   Check (Page_Size >= 16, "host page is at least one vector");
   if Failures /= 0 then
      raise Program_Error with "unsupported page size";
   end if;

   Check
     (Posix_Memalign
        (Allocation'Access,
         Interfaces.C.size_t (Page_Size),
         Interfaces.C.size_t (2 * Page_Size)) = 0,
      "allocate two page-aligned pages");
   if Allocation = System.Null_Address then
      raise Program_Error with "posix_memalign failed";
   end if;

   Check
     (Mprotect
        (Add (Allocation, Page_Size),
         Interfaces.C.size_t (Page_Size),
         No_Access) = 0,
      "protect the page after the test data");

   declare
      Last_Bytes : Byte_Array (0 .. 15);
      for Last_Bytes'Address use Add (Allocation, Page_Size - 16);
      pragma Import (Ada, Last_Bytes);
   begin
      for Raw_Count in Lane_Count_8x16 loop
         for Index in Last_Bytes'Range loop
            Last_Bytes (Index) := U8 (16#80# + Index);
         end loop;

         declare
            Count : constant Lane_Count_8x16 := Raw_Count;
            Data  : Byte_Array (0 .. 15);
            for Data'Address use Add (Allocation, Page_Size - Count);
            pragma Import (Ada, Data);

            Scalar_Load : constant U8x16 := Load_Partial (Data, 0, Count);
            Native_Load : constant U8x16 :=
              Backends.Native.Load_Partial (Data, 0, Count);
            Values : constant U8x16 :=
              From_Lanes
                ([1, 2, 3, 4, 5, 6, 7, 8,
                  9, 10, 11, 12, 13, 14, 15, 16]);
         begin
            for Lane in Lane_Index_8x16 loop
               declare
                  Expected : constant U8 :=
                    (if Lane < Count
                     then U8 (16#80# + 16 - Count + Lane)
                     else 0);
               begin
                  Check
                    (Extract (Scalar_Load, Lane) = Expected,
                     "scalar partial load, count" & Count'Image &
                     ", lane" & Lane'Image);
                  Check
                    (Extract (Native_Load, Lane) = Expected,
                     "native partial load, count" & Count'Image &
                     ", lane" & Lane'Image);
               end;
            end loop;

            Store_Partial (Data, 0, Count, Values);
            for Index in Last_Bytes'Range loop
               Check
                 (Last_Bytes (Index) =
                    (if Index < 16 - Count
                     then U8 (16#80# + Index)
                     else U8 (Index - (16 - Count) + 1)),
                  "scalar partial store, count" & Count'Image &
                  ", byte" & Index'Image);
            end loop;

            for Index in Last_Bytes'Range loop
               Last_Bytes (Index) := U8 (16#80# + Index);
            end loop;
            Backends.Native.Store_Partial (Data, 0, Count, Values);
            for Index in Last_Bytes'Range loop
               Check
                 (Last_Bytes (Index) =
                    (if Index < 16 - Count
                     then U8 (16#80# + Index)
                     else U8 (Index - (16 - Count) + 1)),
                  "native partial store, count" & Count'Image &
                  ", byte" & Index'Image);
            end loop;
         end;
      end loop;
   end;

   declare
      Last_Bytes : Byte_Array (0 .. 31);
      for Last_Bytes'Address use Add (Allocation, Page_Size - 32);
      pragma Import (Ada, Last_Bytes);
      Values : constant Wide.U8x32 :=
        Wide.From_Lanes
          ([for Lane in Wide.Lane_Index_8x32 => U8 (Lane + 1)]);
   begin
      for Raw_Count in Wide.Lane_Count_8x32 loop
         for Index in Last_Bytes'Range loop
            Last_Bytes (Index) := U8 (16#40# + Index);
         end loop;

         declare
            Count : constant Wide.Lane_Count_8x32 := Raw_Count;
            Data  : Byte_Array (0 .. 31);
            for Data'Address use Add (Allocation, Page_Size - Count);
            pragma Import (Ada, Data);

            Scalar_Load : constant Wide.U8x32 :=
              Wide.Load_Partial (Data, 0, Count);
            Native_Load : constant Wide.U8x32 :=
              Wide.Native.Load_Partial (Data, 0, Count);
         begin
            for Lane in Wide.Lane_Index_8x32 loop
               declare
                  Expected : constant U8 :=
                    (if Lane < Count
                     then U8 (16#40# + 32 - Count + Lane)
                     else 0);
               begin
                  Check
                    (Wide.Extract (Scalar_Load, Lane) = Expected,
                     "wide scalar partial load, count" & Count'Image &
                     ", lane" & Lane'Image);
                  Check
                    (Wide.Native.Extract (Native_Load, Lane) = Expected,
                     "wide native partial load, count" & Count'Image &
                     ", lane" & Lane'Image);
               end;
            end loop;

            Wide.Store_Partial (Data, 0, Count, Values);
            for Index in Last_Bytes'Range loop
               Check
                 (Last_Bytes (Index) =
                    (if Index < 32 - Count
                     then U8 (16#40# + Index)
                     else U8 (Index - (32 - Count) + 1)),
                  "wide scalar partial store, count" & Count'Image &
                  ", byte" & Index'Image);
            end loop;

            for Index in Last_Bytes'Range loop
               Last_Bytes (Index) := U8 (16#40# + Index);
            end loop;
            Wide.Native.Store_Partial (Data, 0, Count, Values);
            for Index in Last_Bytes'Range loop
               Check
                 (Last_Bytes (Index) =
                    (if Index < 32 - Count
                     then U8 (16#40# + Index)
                     else U8 (Index - (32 - Count) + 1)),
                  "wide native partial store, count" & Count'Image &
                  ", byte" & Index'Image);
            end loop;
         end;
      end loop;
   end;

   declare
      Needles : constant Byte_Array := [9, 10, 13, 32];
      Empty : constant Byte_Array (1 .. 0) := [];
   begin
      Check
        (Algorithms.Native.Find_First_Of (Empty, Needles) =
           (Found => False, Index => 0),
         "whole-buffer empty scan");
      for Length in Positive range 1 .. 160 loop
         declare
            Data : Byte_Array (1 .. Length);
            Other : constant Byte_Array (1 .. Length) := [others => 65];
            for Data'Address use Add (Allocation, Page_Size - Length);
            pragma Import (Ada, Data);
         begin
            Data := [others => 65];
            Check
              (Algorithms.Scalar.Count_In_Range (Data, 65, 65) = Length
               and then Algorithms.Native.Count_In_Range
                 (Data, 65, 65) = Length
               and then Algorithms.Runtime.Count_In_Range
                 (Data, 65, 65) = Length
               and then Algorithms.Runtime.Count_In_Range
                 (Data, 66, 65) = 0,
               "protected-tail count-in-range length" & Length'Image);
            if Features.Available (Features.AVX2) then
               Check
                 (Algorithms.AVX2.Count_In_Range (Data, 65, 65) = Length
                  and then Algorithms.AVX2.Count_In_Range
                    (Data, 66, 65) = 0,
                  "AVX2 protected-tail count-in-range length" &
                    Length'Image);
            end if;
            Check
              (Algorithms.Scalar.Find_First_Difference (Data, Other) =
                 (Found => False, Index => 0)
               and then Algorithms.Native.Find_First_Difference
                 (Data, Other) = (Found => False, Index => 0)
               and then Algorithms.Runtime.Equal (Data, Other),
               "protected-tail equal buffers length" & Length'Image);
            if Features.Available (Features.AVX2) then
               Check
                 (Algorithms.AVX2.Find_First_Difference (Data, Other) =
                    (Found => False, Index => 0)
                  and then Algorithms.AVX2.Equal (Other, Data),
                  "AVX2 protected-tail equal buffers length" & Length'Image);
            end if;
            Check
              (Algorithms.Scalar.Find_First_Of (Data, Needles) =
                 (Found => False, Index => 0),
               "scalar protected-tail no-match length" & Length'Image);
            Check
              (Algorithms.Native.Find_First_Of (Data, Needles) =
                 (Found => False, Index => 0),
               "native protected-tail no-match length" & Length'Image);
            Check
              (Algorithms.Runtime.Find_First_Of (Data, Needles) =
                 (Found => False, Index => 0),
               "runtime protected-tail no-match length" & Length'Image);
            if Features.Available (Features.AVX2) then
               Check
                 (Algorithms.AVX2.Find_First_Of (Data, Needles) =
                    (Found => False, Index => 0),
                  "AVX2 protected-tail no-match length" & Length'Image);
            end if;
            Data (Data'Last) := Needles (Needles'Last);
            Check
              (Algorithms.Runtime.Find_First_Difference (Data, Other) =
                 (Found => True, Index => Data'Last)
               and then not Algorithms.Runtime.Equal (Data, Other),
               "runtime protected-tail final difference length" &
                 Length'Image);
            if Features.Available (Features.AVX2) then
               Check
                 (Algorithms.AVX2.Find_First_Difference (Other, Data) =
                    (Found => True, Index => Data'Last)
                  and then not Algorithms.AVX2.Equal (Data, Other),
                  "AVX2 protected-tail final difference length" &
                    Length'Image);
            end if;
            Check
              (Algorithms.Native.Find_First_Of (Data, Needles) =
                 (Found => True, Index => Data'Last),
               "native protected-tail final-match length" & Length'Image);
            if Features.Available (Features.AVX2) then
               Check
                 (Algorithms.AVX2.Find_First_Of (Data, Needles) =
                    (Found => True, Index => Data'Last),
                  "AVX2 protected-tail final-match length" & Length'Image);
            end if;
            Data := [others => 250];
            Algorithms.Runtime.Add_Saturate (Data, 10);
            Check
              (Data = [Data'Range => 255],
               "runtime Add_Saturate protected tail length" & Length'Image);
            if Features.Available (Features.AVX2) then
               Data := [others => 250];
               Algorithms.AVX2.Add_Saturate (Data, 10);
               Check
                 (Data = [Data'Range => 255],
                  "AVX2 Add_Saturate protected tail length" & Length'Image);
            end if;
         end;
      end loop;
   end;

   for Length in Positive range 1 .. 33 loop
      declare
         Data : F32_Array (1 .. Length);
         for Data'Address use
           Add (Allocation, Page_Size - Length * (F32'Size / 8));
         pragma Import (Ada, Data);
         Source : constant F32_Array (Data'Range) := [others => 1.0];
      begin
         Data := [others => 1.0];
         Algorithms.Runtime.Scale (Data, 2.0);
         Check
           (Data = [Data'Range => 2.0],
            "runtime F32 scale protected tail length" & Length'Image);
         Algorithms.Runtime.Scale (Data, 0.5);
         Algorithms.Runtime.Clamp (Data, 0.0, 1.0);
         Check
           (Data = [Data'Range => 1.0],
            "runtime F32 clamp protected tail length" & Length'Image);
         Algorithms.Runtime.AXPY (Data, 2.0, Source);
         Check
           (Data = [Data'Range => 3.0],
            "runtime F32 AXPY protected tail length" & Length'Image);
         Algorithms.Runtime.Scale (Data, 1.0 / 3.0);
         Check
           (Algorithms.Runtime.Min_Number (Data) = 1.0
            and then Algorithms.Runtime.Max_Number (Data) = 1.0,
            "runtime F32 min/max protected tail length" & Length'Image);
         Check
           (Algorithms.Runtime.Sum (Data) = F32 (Length),
            "runtime F32 sum protected tail length" & Length'Image);
         Check
           (Algorithms.Runtime.Dot_Product (Data, Data) = F32 (Length),
            "runtime F32 dot protected tail length" & Length'Image);
         if Features.Available (Features.AVX2) then
            Algorithms.AVX2.Scale (Data, 2.0);
            Check
              (Data = [Data'Range => 2.0],
               "AVX2 F32 scale protected tail length" & Length'Image);
            Algorithms.AVX2.Scale (Data, 0.5);
            Algorithms.AVX2.Clamp (Data, 0.0, 1.0);
            Check
              (Data = [Data'Range => 1.0],
               "AVX2 F32 clamp protected tail length" & Length'Image);
            Algorithms.AVX2.AXPY (Data, 2.0, Source);
            Check
              (Data = [Data'Range => 3.0],
               "AVX2 F32 AXPY protected tail length" & Length'Image);
            Algorithms.AVX2.Scale (Data, 1.0 / 3.0);
            Check
              (Algorithms.AVX2.Min_Number (Data) = 1.0
               and then Algorithms.AVX2.Max_Number (Data) = 1.0,
               "AVX2 F32 min/max protected tail length" & Length'Image);
            Check
              (Algorithms.AVX2.Sum (Data) = F32 (Length),
               "AVX2 F32 sum protected tail length" & Length'Image);
            Check
              (Algorithms.AVX2.Dot_Product (Data, Data) = F32 (Length),
               "AVX2 F32 dot protected tail length" & Length'Image);
         end if;
      end;
   end loop;

   for Length in Positive range 1 .. 17 loop
      declare
         Data : F64_Array (1 .. Length);
         for Data'Address use
           Add (Allocation, Page_Size - Length * (F64'Size / 8));
         pragma Import (Ada, Data);
         Source : constant F64_Array (Data'Range) := [others => 1.0];
      begin
         Data := [others => 1.0];
         Algorithms.Runtime.Scale (Data, 2.0);
         Check
           (Data = [Data'Range => 2.0],
            "runtime F64 scale protected tail length" & Length'Image);
         Algorithms.Runtime.Scale (Data, 0.5);
         Algorithms.Runtime.Clamp (Data, 0.0, 1.0);
         Check
           (Data = [Data'Range => 1.0],
            "runtime F64 clamp protected tail length" & Length'Image);
         Algorithms.Runtime.AXPY (Data, 2.0, Source);
         Check
           (Data = [Data'Range => 3.0],
            "runtime F64 AXPY protected tail length" & Length'Image);
         Algorithms.Runtime.Scale (Data, 1.0 / 3.0);
         Check
           (Algorithms.Runtime.Min_Number (Data) = 1.0
            and then Algorithms.Runtime.Max_Number (Data) = 1.0,
            "runtime F64 min/max protected tail length" & Length'Image);
         Check
           (Algorithms.Runtime.Sum (Data) = F64 (Length),
            "runtime F64 sum protected tail length" & Length'Image);
         Check
           (Algorithms.Runtime.Dot_Product (Data, Data) = F64 (Length),
            "runtime F64 dot protected tail length" & Length'Image);
         if Features.Available (Features.AVX2) then
            Algorithms.AVX2.Scale (Data, 2.0);
            Check
              (Data = [Data'Range => 2.0],
               "AVX2 F64 scale protected tail length" & Length'Image);
            Algorithms.AVX2.Scale (Data, 0.5);
            Algorithms.AVX2.Clamp (Data, 0.0, 1.0);
            Check
              (Data = [Data'Range => 1.0],
               "AVX2 F64 clamp protected tail length" & Length'Image);
            Algorithms.AVX2.AXPY (Data, 2.0, Source);
            Check
              (Data = [Data'Range => 3.0],
               "AVX2 F64 AXPY protected tail length" & Length'Image);
            Algorithms.AVX2.Scale (Data, 1.0 / 3.0);
            Check
              (Algorithms.AVX2.Min_Number (Data) = 1.0
               and then Algorithms.AVX2.Max_Number (Data) = 1.0,
               "AVX2 F64 min/max protected tail length" & Length'Image);
            Check
              (Algorithms.AVX2.Sum (Data) = F64 (Length),
               "AVX2 F64 sum protected tail length" & Length'Image);
            Check
              (Algorithms.AVX2.Dot_Product (Data, Data) = F64 (Length),
               "AVX2 F64 dot protected tail length" & Length'Image);
         end if;
      end;
   end loop;

   Check
     (Mprotect
        (Add (Allocation, Page_Size),
         Interfaces.C.size_t (Page_Size),
         Read_Write) = 0,
      "restore the protected page");
   Free (Allocation);

   if Failures = 0 then
      Put_Line ("guard-page memory and complete-algorithm tests: PASS");
   else
      raise Program_Error with Failures'Image & " guard-page failures";
   end if;
exception
   when others =>
      if Allocation /= System.Null_Address then
         declare
            Ignored : constant Interfaces.C.int :=
              Mprotect
                (Add (Allocation, Page_Size),
                 Interfaces.C.size_t (Page_Size),
                 Read_Write);
         begin
            Free (Allocation);
         end;
      end if;
      raise;
end Guard_Page_Tests;
