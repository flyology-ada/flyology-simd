with Flyology_SIMD.Backends.Native;

package body Flyology_SIMD.Wide.Compact_Mechanism is
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;

   function Compress (Value : U8x32; Mask : Mask_8x32) return U8x32 is
      Bits : constant Mask_Bits_8x32 :=
        Mask_Bits_8x32 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_8x32 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              16);
      Low_Selectors : Two_Source_Lane_Selectors_8x16 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_8x16'First)];
      High_Selectors : Two_Source_Lane_Selectors_8x16 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_8x16'First)];
      Low_Valid : Interfaces.Unsigned_16 := 0;
      High_Valid : Interfaces.Unsigned_16 := 0;
      Result_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_8x32 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_8x32'(1), Lane)) /= 0 then
            if Result_Lane < 16 then
               Low_Selectors (Result_Lane) :=
                 (if Lane < 16
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane - 16));
               Low_Valid := Low_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_16'(1), Result_Lane);
            else
               High_Selectors (Result_Lane - 16) :=
                 (if Lane < 16
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane - 16));
               High_Valid := High_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_16'(1), Result_Lane - 16);
            end if;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      declare
         Low_Selected : constant U8x16 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors));
         High_Selected : constant U8x16 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors));
         Zero_Value : constant U8x16 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Low_Valid),
               Low_Selected, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (High_Valid),
               High_Selected, Zero_Value));
      end;
   end Compress;
   function Expand (Value : U8x32; Mask : Mask_8x32) return U8x32 is
      Bits : constant Mask_Bits_8x32 :=
        Mask_Bits_8x32 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_8x32 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              16);
      Low_Selectors : Two_Source_Lane_Selectors_8x16 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_8x16'First)];
      High_Selectors : Two_Source_Lane_Selectors_8x16 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_8x16'First)];
      Low_Valid : Interfaces.Unsigned_16 := 0;
      High_Valid : Interfaces.Unsigned_16 := 0;
      Source_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_8x32 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_8x32'(1), Lane)) /= 0 then
            if Lane < 16 then
               Low_Selectors (Lane) :=
                 (if Source_Lane < 16
                  then Flyology_SIMD.Select_Left_Lane
                         (Source_Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Source_Lane - 16));
               Low_Valid := Low_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_16'(1), Lane);
            else
               High_Selectors (Lane - 16) :=
                 (if Source_Lane < 16
                  then Flyology_SIMD.Select_Left_Lane
                         (Source_Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Source_Lane - 16));
               High_Valid := High_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_16'(1), Lane - 16);
            end if;
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      declare
         Low_Selected : constant U8x16 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors));
         High_Selected : constant U8x16 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors));
         Zero_Value : constant U8x16 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Low_Valid),
               Low_Selected, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (High_Valid),
               High_Selected, Zero_Value));
      end;
   end Expand;
   function Compress (Value : I8x32; Mask : Mask_8x32) return I8x32 is
      Bits : constant Mask_Bits_8x32 :=
        Mask_Bits_8x32 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_8x32 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              16);
      Low_Selectors : Two_Source_Lane_Selectors_8x16 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_8x16'First)];
      High_Selectors : Two_Source_Lane_Selectors_8x16 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_8x16'First)];
      Low_Valid : Interfaces.Unsigned_16 := 0;
      High_Valid : Interfaces.Unsigned_16 := 0;
      Result_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_8x32 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_8x32'(1), Lane)) /= 0 then
            if Result_Lane < 16 then
               Low_Selectors (Result_Lane) :=
                 (if Lane < 16
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane - 16));
               Low_Valid := Low_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_16'(1), Result_Lane);
            else
               High_Selectors (Result_Lane - 16) :=
                 (if Lane < 16
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane - 16));
               High_Valid := High_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_16'(1), Result_Lane - 16);
            end if;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      declare
         Low_Selected : constant I8x16 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors));
         High_Selected : constant I8x16 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors));
         Zero_Value : constant I8x16 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Low_Valid),
               Low_Selected, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (High_Valid),
               High_Selected, Zero_Value));
      end;
   end Compress;
   function Expand (Value : I8x32; Mask : Mask_8x32) return I8x32 is
      Bits : constant Mask_Bits_8x32 :=
        Mask_Bits_8x32 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_8x32 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              16);
      Low_Selectors : Two_Source_Lane_Selectors_8x16 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_8x16'First)];
      High_Selectors : Two_Source_Lane_Selectors_8x16 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_8x16'First)];
      Low_Valid : Interfaces.Unsigned_16 := 0;
      High_Valid : Interfaces.Unsigned_16 := 0;
      Source_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_8x32 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_8x32'(1), Lane)) /= 0 then
            if Lane < 16 then
               Low_Selectors (Lane) :=
                 (if Source_Lane < 16
                  then Flyology_SIMD.Select_Left_Lane
                         (Source_Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Source_Lane - 16));
               Low_Valid := Low_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_16'(1), Lane);
            else
               High_Selectors (Lane - 16) :=
                 (if Source_Lane < 16
                  then Flyology_SIMD.Select_Left_Lane
                         (Source_Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Source_Lane - 16));
               High_Valid := High_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_16'(1), Lane - 16);
            end if;
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      declare
         Low_Selected : constant I8x16 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors));
         High_Selected : constant I8x16 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors));
         Zero_Value : constant I8x16 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Low_Valid),
               Low_Selected, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (High_Valid),
               High_Selected, Zero_Value));
      end;
   end Expand;
   function Compress (Value : U16x16; Mask : Mask_16x16) return U16x16 is
      Bits : constant Mask_Bits_16x16 :=
        Mask_Bits_16x16 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_16x16 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              8);
      Low_Selectors : Two_Source_Lane_Selectors_16x8 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_16x8'First)];
      High_Selectors : Two_Source_Lane_Selectors_16x8 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_16x8'First)];
      Low_Valid : Interfaces.Unsigned_8 := 0;
      High_Valid : Interfaces.Unsigned_8 := 0;
      Result_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_16x16 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_16x16'(1), Lane)) /= 0 then
            if Result_Lane < 8 then
               Low_Selectors (Result_Lane) :=
                 (if Lane < 8
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane - 8));
               Low_Valid := Low_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Result_Lane);
            else
               High_Selectors (Result_Lane - 8) :=
                 (if Lane < 8
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane - 8));
               High_Valid := High_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Result_Lane - 8);
            end if;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      declare
         Low_Selected : constant U16x8 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors));
         High_Selected : constant U16x8 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors));
         Zero_Value : constant U16x8 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Low_Valid),
               Low_Selected, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (High_Valid),
               High_Selected, Zero_Value));
      end;
   end Compress;
   function Expand (Value : U16x16; Mask : Mask_16x16) return U16x16 is
      Bits : constant Mask_Bits_16x16 :=
        Mask_Bits_16x16 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_16x16 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              8);
      Low_Selectors : Two_Source_Lane_Selectors_16x8 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_16x8'First)];
      High_Selectors : Two_Source_Lane_Selectors_16x8 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_16x8'First)];
      Low_Valid : Interfaces.Unsigned_8 := 0;
      High_Valid : Interfaces.Unsigned_8 := 0;
      Source_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_16x16 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_16x16'(1), Lane)) /= 0 then
            if Lane < 8 then
               Low_Selectors (Lane) :=
                 (if Source_Lane < 8
                  then Flyology_SIMD.Select_Left_Lane
                         (Source_Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Source_Lane - 8));
               Low_Valid := Low_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            else
               High_Selectors (Lane - 8) :=
                 (if Source_Lane < 8
                  then Flyology_SIMD.Select_Left_Lane
                         (Source_Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Source_Lane - 8));
               High_Valid := High_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane - 8);
            end if;
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      declare
         Low_Selected : constant U16x8 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors));
         High_Selected : constant U16x8 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors));
         Zero_Value : constant U16x8 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Low_Valid),
               Low_Selected, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (High_Valid),
               High_Selected, Zero_Value));
      end;
   end Expand;
   function Compress (Value : I16x16; Mask : Mask_16x16) return I16x16 is
      Bits : constant Mask_Bits_16x16 :=
        Mask_Bits_16x16 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_16x16 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              8);
      Low_Selectors : Two_Source_Lane_Selectors_16x8 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_16x8'First)];
      High_Selectors : Two_Source_Lane_Selectors_16x8 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_16x8'First)];
      Low_Valid : Interfaces.Unsigned_8 := 0;
      High_Valid : Interfaces.Unsigned_8 := 0;
      Result_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_16x16 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_16x16'(1), Lane)) /= 0 then
            if Result_Lane < 8 then
               Low_Selectors (Result_Lane) :=
                 (if Lane < 8
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane - 8));
               Low_Valid := Low_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Result_Lane);
            else
               High_Selectors (Result_Lane - 8) :=
                 (if Lane < 8
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane - 8));
               High_Valid := High_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Result_Lane - 8);
            end if;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      declare
         Low_Selected : constant I16x8 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors));
         High_Selected : constant I16x8 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors));
         Zero_Value : constant I16x8 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Low_Valid),
               Low_Selected, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (High_Valid),
               High_Selected, Zero_Value));
      end;
   end Compress;
   function Expand (Value : I16x16; Mask : Mask_16x16) return I16x16 is
      Bits : constant Mask_Bits_16x16 :=
        Mask_Bits_16x16 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_16x16 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              8);
      Low_Selectors : Two_Source_Lane_Selectors_16x8 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_16x8'First)];
      High_Selectors : Two_Source_Lane_Selectors_16x8 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_16x8'First)];
      Low_Valid : Interfaces.Unsigned_8 := 0;
      High_Valid : Interfaces.Unsigned_8 := 0;
      Source_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_16x16 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_16x16'(1), Lane)) /= 0 then
            if Lane < 8 then
               Low_Selectors (Lane) :=
                 (if Source_Lane < 8
                  then Flyology_SIMD.Select_Left_Lane
                         (Source_Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Source_Lane - 8));
               Low_Valid := Low_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            else
               High_Selectors (Lane - 8) :=
                 (if Source_Lane < 8
                  then Flyology_SIMD.Select_Left_Lane
                         (Source_Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Source_Lane - 8));
               High_Valid := High_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane - 8);
            end if;
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      declare
         Low_Selected : constant I16x8 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors));
         High_Selected : constant I16x8 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors));
         Zero_Value : constant I16x8 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Low_Valid),
               Low_Selected, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (High_Valid),
               High_Selected, Zero_Value));
      end;
   end Expand;
   function Compress (Value : U32x8; Mask : Mask_32x8) return U32x8 is
      Bits : constant Mask_Bits_32x8 :=
        Mask_Bits_32x8 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_32x8 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              4);
      Low_Selectors : Two_Source_Lane_Selectors_32x4 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_32x4'First)];
      High_Selectors : Two_Source_Lane_Selectors_32x4 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_32x4'First)];
      Low_Valid : Interfaces.Unsigned_8 := 0;
      High_Valid : Interfaces.Unsigned_8 := 0;
      Result_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_32x8 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_32x8'(1), Lane)) /= 0 then
            if Result_Lane < 4 then
               Low_Selectors (Result_Lane) :=
                 (if Lane < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane - 4));
               Low_Valid := Low_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Result_Lane);
            else
               High_Selectors (Result_Lane - 4) :=
                 (if Lane < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane - 4));
               High_Valid := High_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Result_Lane - 4);
            end if;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      declare
         Low_Selected : constant U32x4 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors));
         High_Selected : constant U32x4 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors));
         Zero_Value : constant U32x4 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Low_Valid),
               Low_Selected, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (High_Valid),
               High_Selected, Zero_Value));
      end;
   end Compress;
   function Expand (Value : U32x8; Mask : Mask_32x8) return U32x8 is
      Bits : constant Mask_Bits_32x8 :=
        Mask_Bits_32x8 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_32x8 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              4);
      Low_Selectors : Two_Source_Lane_Selectors_32x4 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_32x4'First)];
      High_Selectors : Two_Source_Lane_Selectors_32x4 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_32x4'First)];
      Low_Valid : Interfaces.Unsigned_8 := 0;
      High_Valid : Interfaces.Unsigned_8 := 0;
      Source_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_32x8 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_32x8'(1), Lane)) /= 0 then
            if Lane < 4 then
               Low_Selectors (Lane) :=
                 (if Source_Lane < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Source_Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Source_Lane - 4));
               Low_Valid := Low_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            else
               High_Selectors (Lane - 4) :=
                 (if Source_Lane < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Source_Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Source_Lane - 4));
               High_Valid := High_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane - 4);
            end if;
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      declare
         Low_Selected : constant U32x4 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors));
         High_Selected : constant U32x4 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors));
         Zero_Value : constant U32x4 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Low_Valid),
               Low_Selected, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (High_Valid),
               High_Selected, Zero_Value));
      end;
   end Expand;
   function Compress (Value : I32x8; Mask : Mask_32x8) return I32x8 is
      Bits : constant Mask_Bits_32x8 :=
        Mask_Bits_32x8 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_32x8 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              4);
      Low_Selectors : Two_Source_Lane_Selectors_32x4 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_32x4'First)];
      High_Selectors : Two_Source_Lane_Selectors_32x4 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_32x4'First)];
      Low_Valid : Interfaces.Unsigned_8 := 0;
      High_Valid : Interfaces.Unsigned_8 := 0;
      Result_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_32x8 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_32x8'(1), Lane)) /= 0 then
            if Result_Lane < 4 then
               Low_Selectors (Result_Lane) :=
                 (if Lane < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane - 4));
               Low_Valid := Low_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Result_Lane);
            else
               High_Selectors (Result_Lane - 4) :=
                 (if Lane < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane - 4));
               High_Valid := High_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Result_Lane - 4);
            end if;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      declare
         Low_Selected : constant I32x4 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors));
         High_Selected : constant I32x4 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors));
         Zero_Value : constant I32x4 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Low_Valid),
               Low_Selected, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (High_Valid),
               High_Selected, Zero_Value));
      end;
   end Compress;
   function Expand (Value : I32x8; Mask : Mask_32x8) return I32x8 is
      Bits : constant Mask_Bits_32x8 :=
        Mask_Bits_32x8 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_32x8 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              4);
      Low_Selectors : Two_Source_Lane_Selectors_32x4 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_32x4'First)];
      High_Selectors : Two_Source_Lane_Selectors_32x4 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_32x4'First)];
      Low_Valid : Interfaces.Unsigned_8 := 0;
      High_Valid : Interfaces.Unsigned_8 := 0;
      Source_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_32x8 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_32x8'(1), Lane)) /= 0 then
            if Lane < 4 then
               Low_Selectors (Lane) :=
                 (if Source_Lane < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Source_Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Source_Lane - 4));
               Low_Valid := Low_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            else
               High_Selectors (Lane - 4) :=
                 (if Source_Lane < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Source_Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Source_Lane - 4));
               High_Valid := High_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane - 4);
            end if;
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      declare
         Low_Selected : constant I32x4 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors));
         High_Selected : constant I32x4 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors));
         Zero_Value : constant I32x4 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Low_Valid),
               Low_Selected, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (High_Valid),
               High_Selected, Zero_Value));
      end;
   end Expand;
   function Compress (Value : U64x4; Mask : Mask_64x4) return U64x4 is
      Bits : constant Mask_Bits_64x4 :=
        Mask_Bits_64x4 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_64x4 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              2);
      Low_Selectors : Two_Source_Lane_Selectors_64x2 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_64x2'First)];
      High_Selectors : Two_Source_Lane_Selectors_64x2 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_64x2'First)];
      Low_Valid : Interfaces.Unsigned_8 := 0;
      High_Valid : Interfaces.Unsigned_8 := 0;
      Result_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_64x4 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_64x4'(1), Lane)) /= 0 then
            if Result_Lane < 2 then
               Low_Selectors (Result_Lane) :=
                 (if Lane < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane - 2));
               Low_Valid := Low_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Result_Lane);
            else
               High_Selectors (Result_Lane - 2) :=
                 (if Lane < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane - 2));
               High_Valid := High_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Result_Lane - 2);
            end if;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      declare
         Low_Selected : constant U64x2 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors));
         High_Selected : constant U64x2 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors));
         Zero_Value : constant U64x2 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Low_Valid),
               Low_Selected, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (High_Valid),
               High_Selected, Zero_Value));
      end;
   end Compress;
   function Expand (Value : U64x4; Mask : Mask_64x4) return U64x4 is
      Bits : constant Mask_Bits_64x4 :=
        Mask_Bits_64x4 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_64x4 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              2);
      Low_Selectors : Two_Source_Lane_Selectors_64x2 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_64x2'First)];
      High_Selectors : Two_Source_Lane_Selectors_64x2 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_64x2'First)];
      Low_Valid : Interfaces.Unsigned_8 := 0;
      High_Valid : Interfaces.Unsigned_8 := 0;
      Source_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_64x4 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_64x4'(1), Lane)) /= 0 then
            if Lane < 2 then
               Low_Selectors (Lane) :=
                 (if Source_Lane < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Source_Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Source_Lane - 2));
               Low_Valid := Low_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            else
               High_Selectors (Lane - 2) :=
                 (if Source_Lane < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Source_Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Source_Lane - 2));
               High_Valid := High_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane - 2);
            end if;
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      declare
         Low_Selected : constant U64x2 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors));
         High_Selected : constant U64x2 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors));
         Zero_Value : constant U64x2 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Low_Valid),
               Low_Selected, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (High_Valid),
               High_Selected, Zero_Value));
      end;
   end Expand;
   function Compress (Value : I64x4; Mask : Mask_64x4) return I64x4 is
      Bits : constant Mask_Bits_64x4 :=
        Mask_Bits_64x4 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_64x4 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              2);
      Low_Selectors : Two_Source_Lane_Selectors_64x2 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_64x2'First)];
      High_Selectors : Two_Source_Lane_Selectors_64x2 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_64x2'First)];
      Low_Valid : Interfaces.Unsigned_8 := 0;
      High_Valid : Interfaces.Unsigned_8 := 0;
      Result_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_64x4 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_64x4'(1), Lane)) /= 0 then
            if Result_Lane < 2 then
               Low_Selectors (Result_Lane) :=
                 (if Lane < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane - 2));
               Low_Valid := Low_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Result_Lane);
            else
               High_Selectors (Result_Lane - 2) :=
                 (if Lane < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane - 2));
               High_Valid := High_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Result_Lane - 2);
            end if;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      declare
         Low_Selected : constant I64x2 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors));
         High_Selected : constant I64x2 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors));
         Zero_Value : constant I64x2 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Low_Valid),
               Low_Selected, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (High_Valid),
               High_Selected, Zero_Value));
      end;
   end Compress;
   function Expand (Value : I64x4; Mask : Mask_64x4) return I64x4 is
      Bits : constant Mask_Bits_64x4 :=
        Mask_Bits_64x4 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_64x4 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              2);
      Low_Selectors : Two_Source_Lane_Selectors_64x2 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_64x2'First)];
      High_Selectors : Two_Source_Lane_Selectors_64x2 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_64x2'First)];
      Low_Valid : Interfaces.Unsigned_8 := 0;
      High_Valid : Interfaces.Unsigned_8 := 0;
      Source_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_64x4 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_64x4'(1), Lane)) /= 0 then
            if Lane < 2 then
               Low_Selectors (Lane) :=
                 (if Source_Lane < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Source_Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Source_Lane - 2));
               Low_Valid := Low_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            else
               High_Selectors (Lane - 2) :=
                 (if Source_Lane < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Source_Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Source_Lane - 2));
               High_Valid := High_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane - 2);
            end if;
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      declare
         Low_Selected : constant I64x2 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors));
         High_Selected : constant I64x2 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors));
         Zero_Value : constant I64x2 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Low_Valid),
               Low_Selected, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (High_Valid),
               High_Selected, Zero_Value));
      end;
   end Expand;
   function Compress (Value : F32x8; Mask : Mask_32x8) return F32x8 is
      Bits : constant Mask_Bits_32x8 :=
        Mask_Bits_32x8 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_32x8 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              4);
      Low_Selectors : Two_Source_Lane_Selectors_32x4 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_32x4'First)];
      High_Selectors : Two_Source_Lane_Selectors_32x4 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_32x4'First)];
      Low_Valid : Interfaces.Unsigned_8 := 0;
      High_Valid : Interfaces.Unsigned_8 := 0;
      Result_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_32x8 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_32x8'(1), Lane)) /= 0 then
            if Result_Lane < 4 then
               Low_Selectors (Result_Lane) :=
                 (if Lane < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane - 4));
               Low_Valid := Low_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Result_Lane);
            else
               High_Selectors (Result_Lane - 4) :=
                 (if Lane < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane - 4));
               High_Valid := High_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Result_Lane - 4);
            end if;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      declare
         Low_Selected : constant F32x4 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors));
         High_Selected : constant F32x4 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors));
         Zero_Value : constant F32x4 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Low_Valid),
               Low_Selected, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (High_Valid),
               High_Selected, Zero_Value));
      end;
   end Compress;
   function Expand (Value : F32x8; Mask : Mask_32x8) return F32x8 is
      Bits : constant Mask_Bits_32x8 :=
        Mask_Bits_32x8 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_32x8 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              4);
      Low_Selectors : Two_Source_Lane_Selectors_32x4 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_32x4'First)];
      High_Selectors : Two_Source_Lane_Selectors_32x4 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_32x4'First)];
      Low_Valid : Interfaces.Unsigned_8 := 0;
      High_Valid : Interfaces.Unsigned_8 := 0;
      Source_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_32x8 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_32x8'(1), Lane)) /= 0 then
            if Lane < 4 then
               Low_Selectors (Lane) :=
                 (if Source_Lane < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Source_Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Source_Lane - 4));
               Low_Valid := Low_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            else
               High_Selectors (Lane - 4) :=
                 (if Source_Lane < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Source_Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Source_Lane - 4));
               High_Valid := High_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane - 4);
            end if;
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      declare
         Low_Selected : constant F32x4 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors));
         High_Selected : constant F32x4 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors));
         Zero_Value : constant F32x4 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Low_Valid),
               Low_Selected, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (High_Valid),
               High_Selected, Zero_Value));
      end;
   end Expand;
   function Compress (Value : F64x4; Mask : Mask_64x4) return F64x4 is
      Bits : constant Mask_Bits_64x4 :=
        Mask_Bits_64x4 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_64x4 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              2);
      Low_Selectors : Two_Source_Lane_Selectors_64x2 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_64x2'First)];
      High_Selectors : Two_Source_Lane_Selectors_64x2 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_64x2'First)];
      Low_Valid : Interfaces.Unsigned_8 := 0;
      High_Valid : Interfaces.Unsigned_8 := 0;
      Result_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_64x4 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_64x4'(1), Lane)) /= 0 then
            if Result_Lane < 2 then
               Low_Selectors (Result_Lane) :=
                 (if Lane < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane - 2));
               Low_Valid := Low_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Result_Lane);
            else
               High_Selectors (Result_Lane - 2) :=
                 (if Lane < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane - 2));
               High_Valid := High_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Result_Lane - 2);
            end if;
            Result_Lane := Result_Lane + 1;
         end if;
      end loop;
      declare
         Low_Selected : constant F64x2 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors));
         High_Selected : constant F64x2 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors));
         Zero_Value : constant F64x2 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Low_Valid),
               Low_Selected, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (High_Valid),
               High_Selected, Zero_Value));
      end;
   end Compress;
   function Expand (Value : F64x4; Mask : Mask_64x4) return F64x4 is
      Bits : constant Mask_Bits_64x4 :=
        Mask_Bits_64x4 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.Low))
        or Interfaces.Shift_Left
             (Mask_Bits_64x4 (Flyology_SIMD.Backends.Native.To_Bit_Mask (Mask.High)),
              2);
      Low_Selectors : Two_Source_Lane_Selectors_64x2 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_64x2'First)];
      High_Selectors : Two_Source_Lane_Selectors_64x2 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_64x2'First)];
      Low_Valid : Interfaces.Unsigned_8 := 0;
      High_Valid : Interfaces.Unsigned_8 := 0;
      Source_Lane : Natural := 0;
   begin
      for Lane in Lane_Index_64x4 loop
         if (Bits and Interfaces.Shift_Left (Mask_Bits_64x4'(1), Lane)) /= 0 then
            if Lane < 2 then
               Low_Selectors (Lane) :=
                 (if Source_Lane < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Source_Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Source_Lane - 2));
               Low_Valid := Low_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            else
               High_Selectors (Lane - 2) :=
                 (if Source_Lane < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Source_Lane)
                  else Flyology_SIMD.Select_Right_Lane
                         (Source_Lane - 2));
               High_Valid := High_Valid or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane - 2);
            end if;
            Source_Lane := Source_Lane + 1;
         end if;
      end loop;
      declare
         Low_Selected : constant F64x2 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors));
         High_Selected : constant F64x2 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Value.Low, Value.High,
              Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors));
         Zero_Value : constant F64x2 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Low_Valid),
               Low_Selected, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (High_Valid),
               High_Selected, Zero_Value));
      end;
   end Expand;
end Flyology_SIMD.Wide.Compact_Mechanism;
