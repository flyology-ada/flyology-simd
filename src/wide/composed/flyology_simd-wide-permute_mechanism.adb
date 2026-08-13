with Flyology_SIMD.Backends.Native;

package body Flyology_SIMD.Wide.Permute_Mechanism is
   use type Interfaces.Unsigned_8;
   use type Interfaces.Unsigned_16;
   use type Interfaces.Unsigned_32;

   function Permute_Lanes
     (Value : U8x32; Map : Lane_Map_8x32) return U8x32
   is
      Low_Selectors : Two_Source_Lane_Selectors_8x16;
      High_Selectors : Two_Source_Lane_Selectors_8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         declare
            Low_Source : constant Lane_Index_8x32 := Map.Selectors (Lane);
            High_Source : constant Lane_Index_8x32 :=
              Map.Selectors (Lane + 16);
         begin
            Low_Selectors (Lane) :=
              (if Low_Source < 16
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_8x16'(Low_Source))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_8x16'(Low_Source - 16)));
            High_Selectors (Lane) :=
              (if High_Source < 16
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_8x16'(High_Source))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_8x16'(High_Source - 16)));
         end;
      end loop;
      return
        (Low => Flyology_SIMD.Backends.Native.Permute_Lanes
           (Value.Low, Value.High,
            Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors)),
         High => Flyology_SIMD.Backends.Native.Permute_Lanes
           (Value.Low, Value.High,
            Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors)));
   end Permute_Lanes;
   function Permute_Lanes
     (Left, Right : U8x32; Map : Two_Source_Lane_Map_8x32) return U8x32
   is
      Left_Low_Selectors : Two_Source_Lane_Selectors_8x16 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_8x16'First)];
      Left_High_Selectors : Two_Source_Lane_Selectors_8x16 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_8x16'First)];
      Right_Low_Selectors : Two_Source_Lane_Selectors_8x16 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_8x16'First)];
      Right_High_Selectors : Two_Source_Lane_Selectors_8x16 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_8x16'First)];
      Low_Right_Bits : Interfaces.Unsigned_16 := 0;
      High_Right_Bits : Interfaces.Unsigned_16 := 0;
   begin
      for Lane in Lane_Index_8x16 loop
         declare
            Low_Selector : constant Two_Source_Lane_Selector_8x32 := Map.Selectors (Lane);
            High_Selector : constant Two_Source_Lane_Selector_8x32 :=
              Map.Selectors (Lane + 16);
         begin
            if Low_Selector.From_Right then
               Right_Low_Selectors (Lane) :=
                 (if Low_Selector.Lane < 16
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_8x16'(Low_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_8x16'(Low_Selector.Lane - 16)));
               Low_Right_Bits := Low_Right_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_16'(1), Lane);
            else
               Left_Low_Selectors (Lane) :=
                 (if Low_Selector.Lane < 16
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_8x16'(Low_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_8x16'(Low_Selector.Lane - 16)));
            end if;
            if High_Selector.From_Right then
               Right_High_Selectors (Lane) :=
                 (if High_Selector.Lane < 16
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_8x16'(High_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_8x16'(High_Selector.Lane - 16)));
               High_Right_Bits := High_Right_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_16'(1), Lane);
            else
               Left_High_Selectors (Lane) :=
                 (if High_Selector.Lane < 16
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_8x16'(High_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_8x16'(High_Selector.Lane - 16)));
            end if;
         end;
      end loop;
      declare
         Left_Low : constant U8x16 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Left.Low, Left.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Left_Low_Selectors));
         Left_High : constant U8x16 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Left.Low, Left.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Left_High_Selectors));
         Right_Low : constant U8x16 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Right.Low, Right.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Right_Low_Selectors));
         Right_High : constant U8x16 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Right.Low, Right.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Right_High_Selectors));
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask
                 (Low_Right_Bits), Right_Low, Left_Low),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask
                 (High_Right_Bits), Right_High, Left_High));
      end;
   end Permute_Lanes;
   function Reverse_Lanes (Value : U8x32) return U8x32 is
     (Permute_Lanes
        (Value, (Selectors =>
           [for Lane in Lane_Index_8x32 => 31 - Lane])));
   function Interleave_Low
     (Left, Right : U8x32) return U8x32
   is
      Selectors : constant Two_Source_Lane_Selectors_8x32 :=
        [for Lane in Lane_Index_8x32 => (if Lane mod 2 = 0 then Flyology_SIMD.Wide.Select_Left_Lane (Lane / 2) else Flyology_SIMD.Wide.Select_Right_Lane (Lane / 2))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Interleave_Low;
   function Interleave_High
     (Left, Right : U8x32) return U8x32
   is
      Selectors : constant Two_Source_Lane_Selectors_8x32 :=
        [for Lane in Lane_Index_8x32 => (if Lane mod 2 = 0 then Flyology_SIMD.Wide.Select_Left_Lane (16 + Lane / 2) else Flyology_SIMD.Wide.Select_Right_Lane (16 + Lane / 2))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Interleave_High;
   function Deinterleave_Even
     (Left, Right : U8x32) return U8x32
   is
      Selectors : constant Two_Source_Lane_Selectors_8x32 :=
        [for Lane in Lane_Index_8x32 => (if Lane < 16 then Flyology_SIMD.Wide.Select_Left_Lane (2 * Lane) else Flyology_SIMD.Wide.Select_Right_Lane (2 * (Lane - 16)))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Deinterleave_Even;
   function Deinterleave_Odd
     (Left, Right : U8x32) return U8x32
   is
      Selectors : constant Two_Source_Lane_Selectors_8x32 :=
        [for Lane in Lane_Index_8x32 => (if Lane < 16 then Flyology_SIMD.Wide.Select_Left_Lane (2 * Lane + 1) else Flyology_SIMD.Wide.Select_Right_Lane (2 * (Lane - 16) + 1))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Deinterleave_Odd;
   function Slide_Lanes_Toward_Low
     (Value : U8x32; Count : Natural) return U8x32
   is
      Selectors : Lane_Selectors_8x32 := [others => 0];
      Valid_Bits : Interfaces.Unsigned_32 := 0;
   begin
      if Count < 32 then
         for Lane in Lane_Index_8x32 loop
            if Lane < 32 - Count then
               Selectors (Lane) := Lane + Count;
               Valid_Bits := Valid_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_32'(1), Lane);
            end if;
         end loop;
      end if;
      declare
         Selected : constant U8x32 :=
           Permute_Lanes (Value, (Selectors => Selectors));
         Zero_Value : constant U8x16 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Valid_Bits and Interfaces.Unsigned_32 (65535))),
               Selected.Low, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Interfaces.Shift_Right (Valid_Bits, 16))),
               Selected.High, Zero_Value));
      end;
   end Slide_Lanes_Toward_Low;
   function Slide_Lanes_Toward_High
     (Value : U8x32; Count : Natural) return U8x32
   is
      Selectors : Lane_Selectors_8x32 := [others => 0];
      Valid_Bits : Interfaces.Unsigned_32 := 0;
   begin
      if Count < 32 then
         for Lane in Lane_Index_8x32 loop
            if Lane >= Count then
               Selectors (Lane) := Lane - Count;
               Valid_Bits := Valid_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_32'(1), Lane);
            end if;
         end loop;
      end if;
      declare
         Selected : constant U8x32 :=
           Permute_Lanes (Value, (Selectors => Selectors));
         Zero_Value : constant U8x16 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Valid_Bits and Interfaces.Unsigned_32 (65535))),
               Selected.Low, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Interfaces.Shift_Right (Valid_Bits, 16))),
               Selected.High, Zero_Value));
      end;
   end Slide_Lanes_Toward_High;
   function Permute_Lanes
     (Value : I8x32; Map : Lane_Map_8x32) return I8x32
   is
      Low_Selectors : Two_Source_Lane_Selectors_8x16;
      High_Selectors : Two_Source_Lane_Selectors_8x16;
   begin
      for Lane in Lane_Index_8x16 loop
         declare
            Low_Source : constant Lane_Index_8x32 := Map.Selectors (Lane);
            High_Source : constant Lane_Index_8x32 :=
              Map.Selectors (Lane + 16);
         begin
            Low_Selectors (Lane) :=
              (if Low_Source < 16
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_8x16'(Low_Source))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_8x16'(Low_Source - 16)));
            High_Selectors (Lane) :=
              (if High_Source < 16
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_8x16'(High_Source))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_8x16'(High_Source - 16)));
         end;
      end loop;
      return
        (Low => Flyology_SIMD.Backends.Native.Permute_Lanes
           (Value.Low, Value.High,
            Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors)),
         High => Flyology_SIMD.Backends.Native.Permute_Lanes
           (Value.Low, Value.High,
            Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors)));
   end Permute_Lanes;
   function Permute_Lanes
     (Left, Right : I8x32; Map : Two_Source_Lane_Map_8x32) return I8x32
   is
      Left_Low_Selectors : Two_Source_Lane_Selectors_8x16 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_8x16'First)];
      Left_High_Selectors : Two_Source_Lane_Selectors_8x16 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_8x16'First)];
      Right_Low_Selectors : Two_Source_Lane_Selectors_8x16 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_8x16'First)];
      Right_High_Selectors : Two_Source_Lane_Selectors_8x16 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_8x16'First)];
      Low_Right_Bits : Interfaces.Unsigned_16 := 0;
      High_Right_Bits : Interfaces.Unsigned_16 := 0;
   begin
      for Lane in Lane_Index_8x16 loop
         declare
            Low_Selector : constant Two_Source_Lane_Selector_8x32 := Map.Selectors (Lane);
            High_Selector : constant Two_Source_Lane_Selector_8x32 :=
              Map.Selectors (Lane + 16);
         begin
            if Low_Selector.From_Right then
               Right_Low_Selectors (Lane) :=
                 (if Low_Selector.Lane < 16
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_8x16'(Low_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_8x16'(Low_Selector.Lane - 16)));
               Low_Right_Bits := Low_Right_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_16'(1), Lane);
            else
               Left_Low_Selectors (Lane) :=
                 (if Low_Selector.Lane < 16
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_8x16'(Low_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_8x16'(Low_Selector.Lane - 16)));
            end if;
            if High_Selector.From_Right then
               Right_High_Selectors (Lane) :=
                 (if High_Selector.Lane < 16
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_8x16'(High_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_8x16'(High_Selector.Lane - 16)));
               High_Right_Bits := High_Right_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_16'(1), Lane);
            else
               Left_High_Selectors (Lane) :=
                 (if High_Selector.Lane < 16
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_8x16'(High_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_8x16'(High_Selector.Lane - 16)));
            end if;
         end;
      end loop;
      declare
         Left_Low : constant I8x16 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Left.Low, Left.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Left_Low_Selectors));
         Left_High : constant I8x16 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Left.Low, Left.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Left_High_Selectors));
         Right_Low : constant I8x16 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Right.Low, Right.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Right_Low_Selectors));
         Right_High : constant I8x16 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Right.Low, Right.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Right_High_Selectors));
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask
                 (Low_Right_Bits), Right_Low, Left_Low),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask
                 (High_Right_Bits), Right_High, Left_High));
      end;
   end Permute_Lanes;
   function Reverse_Lanes (Value : I8x32) return I8x32 is
     (Permute_Lanes
        (Value, (Selectors =>
           [for Lane in Lane_Index_8x32 => 31 - Lane])));
   function Interleave_Low
     (Left, Right : I8x32) return I8x32
   is
      Selectors : constant Two_Source_Lane_Selectors_8x32 :=
        [for Lane in Lane_Index_8x32 => (if Lane mod 2 = 0 then Flyology_SIMD.Wide.Select_Left_Lane (Lane / 2) else Flyology_SIMD.Wide.Select_Right_Lane (Lane / 2))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Interleave_Low;
   function Interleave_High
     (Left, Right : I8x32) return I8x32
   is
      Selectors : constant Two_Source_Lane_Selectors_8x32 :=
        [for Lane in Lane_Index_8x32 => (if Lane mod 2 = 0 then Flyology_SIMD.Wide.Select_Left_Lane (16 + Lane / 2) else Flyology_SIMD.Wide.Select_Right_Lane (16 + Lane / 2))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Interleave_High;
   function Deinterleave_Even
     (Left, Right : I8x32) return I8x32
   is
      Selectors : constant Two_Source_Lane_Selectors_8x32 :=
        [for Lane in Lane_Index_8x32 => (if Lane < 16 then Flyology_SIMD.Wide.Select_Left_Lane (2 * Lane) else Flyology_SIMD.Wide.Select_Right_Lane (2 * (Lane - 16)))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Deinterleave_Even;
   function Deinterleave_Odd
     (Left, Right : I8x32) return I8x32
   is
      Selectors : constant Two_Source_Lane_Selectors_8x32 :=
        [for Lane in Lane_Index_8x32 => (if Lane < 16 then Flyology_SIMD.Wide.Select_Left_Lane (2 * Lane + 1) else Flyology_SIMD.Wide.Select_Right_Lane (2 * (Lane - 16) + 1))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Deinterleave_Odd;
   function Slide_Lanes_Toward_Low
     (Value : I8x32; Count : Natural) return I8x32
   is
      Selectors : Lane_Selectors_8x32 := [others => 0];
      Valid_Bits : Interfaces.Unsigned_32 := 0;
   begin
      if Count < 32 then
         for Lane in Lane_Index_8x32 loop
            if Lane < 32 - Count then
               Selectors (Lane) := Lane + Count;
               Valid_Bits := Valid_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_32'(1), Lane);
            end if;
         end loop;
      end if;
      declare
         Selected : constant I8x32 :=
           Permute_Lanes (Value, (Selectors => Selectors));
         Zero_Value : constant I8x16 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Valid_Bits and Interfaces.Unsigned_32 (65535))),
               Selected.Low, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Interfaces.Shift_Right (Valid_Bits, 16))),
               Selected.High, Zero_Value));
      end;
   end Slide_Lanes_Toward_Low;
   function Slide_Lanes_Toward_High
     (Value : I8x32; Count : Natural) return I8x32
   is
      Selectors : Lane_Selectors_8x32 := [others => 0];
      Valid_Bits : Interfaces.Unsigned_32 := 0;
   begin
      if Count < 32 then
         for Lane in Lane_Index_8x32 loop
            if Lane >= Count then
               Selectors (Lane) := Lane - Count;
               Valid_Bits := Valid_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_32'(1), Lane);
            end if;
         end loop;
      end if;
      declare
         Selected : constant I8x32 :=
           Permute_Lanes (Value, (Selectors => Selectors));
         Zero_Value : constant I8x16 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Valid_Bits and Interfaces.Unsigned_32 (65535))),
               Selected.Low, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_16 (Interfaces.Shift_Right (Valid_Bits, 16))),
               Selected.High, Zero_Value));
      end;
   end Slide_Lanes_Toward_High;
   function Permute_Lanes
     (Value : U16x16; Map : Lane_Map_16x16) return U16x16
   is
      Low_Selectors : Two_Source_Lane_Selectors_16x8;
      High_Selectors : Two_Source_Lane_Selectors_16x8;
   begin
      for Lane in Lane_Index_16x8 loop
         declare
            Low_Source : constant Lane_Index_16x16 := Map.Selectors (Lane);
            High_Source : constant Lane_Index_16x16 :=
              Map.Selectors (Lane + 8);
         begin
            Low_Selectors (Lane) :=
              (if Low_Source < 8
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_16x8'(Low_Source))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_16x8'(Low_Source - 8)));
            High_Selectors (Lane) :=
              (if High_Source < 8
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_16x8'(High_Source))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_16x8'(High_Source - 8)));
         end;
      end loop;
      return
        (Low => Flyology_SIMD.Backends.Native.Permute_Lanes
           (Value.Low, Value.High,
            Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors)),
         High => Flyology_SIMD.Backends.Native.Permute_Lanes
           (Value.Low, Value.High,
            Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors)));
   end Permute_Lanes;
   function Permute_Lanes
     (Left, Right : U16x16; Map : Two_Source_Lane_Map_16x16) return U16x16
   is
      Left_Low_Selectors : Two_Source_Lane_Selectors_16x8 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_16x8'First)];
      Left_High_Selectors : Two_Source_Lane_Selectors_16x8 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_16x8'First)];
      Right_Low_Selectors : Two_Source_Lane_Selectors_16x8 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_16x8'First)];
      Right_High_Selectors : Two_Source_Lane_Selectors_16x8 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_16x8'First)];
      Low_Right_Bits : Interfaces.Unsigned_8 := 0;
      High_Right_Bits : Interfaces.Unsigned_8 := 0;
   begin
      for Lane in Lane_Index_16x8 loop
         declare
            Low_Selector : constant Two_Source_Lane_Selector_16x16 := Map.Selectors (Lane);
            High_Selector : constant Two_Source_Lane_Selector_16x16 :=
              Map.Selectors (Lane + 8);
         begin
            if Low_Selector.From_Right then
               Right_Low_Selectors (Lane) :=
                 (if Low_Selector.Lane < 8
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_16x8'(Low_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_16x8'(Low_Selector.Lane - 8)));
               Low_Right_Bits := Low_Right_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            else
               Left_Low_Selectors (Lane) :=
                 (if Low_Selector.Lane < 8
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_16x8'(Low_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_16x8'(Low_Selector.Lane - 8)));
            end if;
            if High_Selector.From_Right then
               Right_High_Selectors (Lane) :=
                 (if High_Selector.Lane < 8
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_16x8'(High_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_16x8'(High_Selector.Lane - 8)));
               High_Right_Bits := High_Right_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            else
               Left_High_Selectors (Lane) :=
                 (if High_Selector.Lane < 8
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_16x8'(High_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_16x8'(High_Selector.Lane - 8)));
            end if;
         end;
      end loop;
      declare
         Left_Low : constant U16x8 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Left.Low, Left.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Left_Low_Selectors));
         Left_High : constant U16x8 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Left.Low, Left.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Left_High_Selectors));
         Right_Low : constant U16x8 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Right.Low, Right.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Right_Low_Selectors));
         Right_High : constant U16x8 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Right.Low, Right.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Right_High_Selectors));
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask
                 (Low_Right_Bits), Right_Low, Left_Low),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask
                 (High_Right_Bits), Right_High, Left_High));
      end;
   end Permute_Lanes;
   function Reverse_Lanes (Value : U16x16) return U16x16 is
     (Permute_Lanes
        (Value, (Selectors =>
           [for Lane in Lane_Index_16x16 => 15 - Lane])));
   function Interleave_Low
     (Left, Right : U16x16) return U16x16
   is
      Selectors : constant Two_Source_Lane_Selectors_16x16 :=
        [for Lane in Lane_Index_16x16 => (if Lane mod 2 = 0 then Flyology_SIMD.Wide.Select_Left_Lane (Lane / 2) else Flyology_SIMD.Wide.Select_Right_Lane (Lane / 2))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Interleave_Low;
   function Interleave_High
     (Left, Right : U16x16) return U16x16
   is
      Selectors : constant Two_Source_Lane_Selectors_16x16 :=
        [for Lane in Lane_Index_16x16 => (if Lane mod 2 = 0 then Flyology_SIMD.Wide.Select_Left_Lane (8 + Lane / 2) else Flyology_SIMD.Wide.Select_Right_Lane (8 + Lane / 2))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Interleave_High;
   function Deinterleave_Even
     (Left, Right : U16x16) return U16x16
   is
      Selectors : constant Two_Source_Lane_Selectors_16x16 :=
        [for Lane in Lane_Index_16x16 => (if Lane < 8 then Flyology_SIMD.Wide.Select_Left_Lane (2 * Lane) else Flyology_SIMD.Wide.Select_Right_Lane (2 * (Lane - 8)))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Deinterleave_Even;
   function Deinterleave_Odd
     (Left, Right : U16x16) return U16x16
   is
      Selectors : constant Two_Source_Lane_Selectors_16x16 :=
        [for Lane in Lane_Index_16x16 => (if Lane < 8 then Flyology_SIMD.Wide.Select_Left_Lane (2 * Lane + 1) else Flyology_SIMD.Wide.Select_Right_Lane (2 * (Lane - 8) + 1))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Deinterleave_Odd;
   function Slide_Lanes_Toward_Low
     (Value : U16x16; Count : Natural) return U16x16
   is
      Selectors : Lane_Selectors_16x16 := [others => 0];
      Valid_Bits : Interfaces.Unsigned_16 := 0;
   begin
      if Count < 16 then
         for Lane in Lane_Index_16x16 loop
            if Lane < 16 - Count then
               Selectors (Lane) := Lane + Count;
               Valid_Bits := Valid_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_16'(1), Lane);
            end if;
         end loop;
      end if;
      declare
         Selected : constant U16x16 :=
           Permute_Lanes (Value, (Selectors => Selectors));
         Zero_Value : constant U16x8 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Valid_Bits and Interfaces.Unsigned_16 (255))),
               Selected.Low, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Interfaces.Shift_Right (Valid_Bits, 8))),
               Selected.High, Zero_Value));
      end;
   end Slide_Lanes_Toward_Low;
   function Slide_Lanes_Toward_High
     (Value : U16x16; Count : Natural) return U16x16
   is
      Selectors : Lane_Selectors_16x16 := [others => 0];
      Valid_Bits : Interfaces.Unsigned_16 := 0;
   begin
      if Count < 16 then
         for Lane in Lane_Index_16x16 loop
            if Lane >= Count then
               Selectors (Lane) := Lane - Count;
               Valid_Bits := Valid_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_16'(1), Lane);
            end if;
         end loop;
      end if;
      declare
         Selected : constant U16x16 :=
           Permute_Lanes (Value, (Selectors => Selectors));
         Zero_Value : constant U16x8 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Valid_Bits and Interfaces.Unsigned_16 (255))),
               Selected.Low, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Interfaces.Shift_Right (Valid_Bits, 8))),
               Selected.High, Zero_Value));
      end;
   end Slide_Lanes_Toward_High;
   function Permute_Lanes
     (Value : I16x16; Map : Lane_Map_16x16) return I16x16
   is
      Low_Selectors : Two_Source_Lane_Selectors_16x8;
      High_Selectors : Two_Source_Lane_Selectors_16x8;
   begin
      for Lane in Lane_Index_16x8 loop
         declare
            Low_Source : constant Lane_Index_16x16 := Map.Selectors (Lane);
            High_Source : constant Lane_Index_16x16 :=
              Map.Selectors (Lane + 8);
         begin
            Low_Selectors (Lane) :=
              (if Low_Source < 8
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_16x8'(Low_Source))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_16x8'(Low_Source - 8)));
            High_Selectors (Lane) :=
              (if High_Source < 8
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_16x8'(High_Source))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_16x8'(High_Source - 8)));
         end;
      end loop;
      return
        (Low => Flyology_SIMD.Backends.Native.Permute_Lanes
           (Value.Low, Value.High,
            Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors)),
         High => Flyology_SIMD.Backends.Native.Permute_Lanes
           (Value.Low, Value.High,
            Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors)));
   end Permute_Lanes;
   function Permute_Lanes
     (Left, Right : I16x16; Map : Two_Source_Lane_Map_16x16) return I16x16
   is
      Left_Low_Selectors : Two_Source_Lane_Selectors_16x8 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_16x8'First)];
      Left_High_Selectors : Two_Source_Lane_Selectors_16x8 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_16x8'First)];
      Right_Low_Selectors : Two_Source_Lane_Selectors_16x8 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_16x8'First)];
      Right_High_Selectors : Two_Source_Lane_Selectors_16x8 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_16x8'First)];
      Low_Right_Bits : Interfaces.Unsigned_8 := 0;
      High_Right_Bits : Interfaces.Unsigned_8 := 0;
   begin
      for Lane in Lane_Index_16x8 loop
         declare
            Low_Selector : constant Two_Source_Lane_Selector_16x16 := Map.Selectors (Lane);
            High_Selector : constant Two_Source_Lane_Selector_16x16 :=
              Map.Selectors (Lane + 8);
         begin
            if Low_Selector.From_Right then
               Right_Low_Selectors (Lane) :=
                 (if Low_Selector.Lane < 8
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_16x8'(Low_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_16x8'(Low_Selector.Lane - 8)));
               Low_Right_Bits := Low_Right_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            else
               Left_Low_Selectors (Lane) :=
                 (if Low_Selector.Lane < 8
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_16x8'(Low_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_16x8'(Low_Selector.Lane - 8)));
            end if;
            if High_Selector.From_Right then
               Right_High_Selectors (Lane) :=
                 (if High_Selector.Lane < 8
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_16x8'(High_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_16x8'(High_Selector.Lane - 8)));
               High_Right_Bits := High_Right_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            else
               Left_High_Selectors (Lane) :=
                 (if High_Selector.Lane < 8
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_16x8'(High_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_16x8'(High_Selector.Lane - 8)));
            end if;
         end;
      end loop;
      declare
         Left_Low : constant I16x8 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Left.Low, Left.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Left_Low_Selectors));
         Left_High : constant I16x8 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Left.Low, Left.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Left_High_Selectors));
         Right_Low : constant I16x8 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Right.Low, Right.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Right_Low_Selectors));
         Right_High : constant I16x8 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Right.Low, Right.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Right_High_Selectors));
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask
                 (Low_Right_Bits), Right_Low, Left_Low),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask
                 (High_Right_Bits), Right_High, Left_High));
      end;
   end Permute_Lanes;
   function Reverse_Lanes (Value : I16x16) return I16x16 is
     (Permute_Lanes
        (Value, (Selectors =>
           [for Lane in Lane_Index_16x16 => 15 - Lane])));
   function Interleave_Low
     (Left, Right : I16x16) return I16x16
   is
      Selectors : constant Two_Source_Lane_Selectors_16x16 :=
        [for Lane in Lane_Index_16x16 => (if Lane mod 2 = 0 then Flyology_SIMD.Wide.Select_Left_Lane (Lane / 2) else Flyology_SIMD.Wide.Select_Right_Lane (Lane / 2))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Interleave_Low;
   function Interleave_High
     (Left, Right : I16x16) return I16x16
   is
      Selectors : constant Two_Source_Lane_Selectors_16x16 :=
        [for Lane in Lane_Index_16x16 => (if Lane mod 2 = 0 then Flyology_SIMD.Wide.Select_Left_Lane (8 + Lane / 2) else Flyology_SIMD.Wide.Select_Right_Lane (8 + Lane / 2))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Interleave_High;
   function Deinterleave_Even
     (Left, Right : I16x16) return I16x16
   is
      Selectors : constant Two_Source_Lane_Selectors_16x16 :=
        [for Lane in Lane_Index_16x16 => (if Lane < 8 then Flyology_SIMD.Wide.Select_Left_Lane (2 * Lane) else Flyology_SIMD.Wide.Select_Right_Lane (2 * (Lane - 8)))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Deinterleave_Even;
   function Deinterleave_Odd
     (Left, Right : I16x16) return I16x16
   is
      Selectors : constant Two_Source_Lane_Selectors_16x16 :=
        [for Lane in Lane_Index_16x16 => (if Lane < 8 then Flyology_SIMD.Wide.Select_Left_Lane (2 * Lane + 1) else Flyology_SIMD.Wide.Select_Right_Lane (2 * (Lane - 8) + 1))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Deinterleave_Odd;
   function Slide_Lanes_Toward_Low
     (Value : I16x16; Count : Natural) return I16x16
   is
      Selectors : Lane_Selectors_16x16 := [others => 0];
      Valid_Bits : Interfaces.Unsigned_16 := 0;
   begin
      if Count < 16 then
         for Lane in Lane_Index_16x16 loop
            if Lane < 16 - Count then
               Selectors (Lane) := Lane + Count;
               Valid_Bits := Valid_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_16'(1), Lane);
            end if;
         end loop;
      end if;
      declare
         Selected : constant I16x16 :=
           Permute_Lanes (Value, (Selectors => Selectors));
         Zero_Value : constant I16x8 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Valid_Bits and Interfaces.Unsigned_16 (255))),
               Selected.Low, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Interfaces.Shift_Right (Valid_Bits, 8))),
               Selected.High, Zero_Value));
      end;
   end Slide_Lanes_Toward_Low;
   function Slide_Lanes_Toward_High
     (Value : I16x16; Count : Natural) return I16x16
   is
      Selectors : Lane_Selectors_16x16 := [others => 0];
      Valid_Bits : Interfaces.Unsigned_16 := 0;
   begin
      if Count < 16 then
         for Lane in Lane_Index_16x16 loop
            if Lane >= Count then
               Selectors (Lane) := Lane - Count;
               Valid_Bits := Valid_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_16'(1), Lane);
            end if;
         end loop;
      end if;
      declare
         Selected : constant I16x16 :=
           Permute_Lanes (Value, (Selectors => Selectors));
         Zero_Value : constant I16x8 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Valid_Bits and Interfaces.Unsigned_16 (255))),
               Selected.Low, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Interfaces.Shift_Right (Valid_Bits, 8))),
               Selected.High, Zero_Value));
      end;
   end Slide_Lanes_Toward_High;
   function Permute_Lanes
     (Value : U32x8; Map : Lane_Map_32x8) return U32x8
   is
      Low_Selectors : Two_Source_Lane_Selectors_32x4;
      High_Selectors : Two_Source_Lane_Selectors_32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         declare
            Low_Source : constant Lane_Index_32x8 := Map.Selectors (Lane);
            High_Source : constant Lane_Index_32x8 :=
              Map.Selectors (Lane + 4);
         begin
            Low_Selectors (Lane) :=
              (if Low_Source < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_32x4'(Low_Source))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_32x4'(Low_Source - 4)));
            High_Selectors (Lane) :=
              (if High_Source < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_32x4'(High_Source))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_32x4'(High_Source - 4)));
         end;
      end loop;
      return
        (Low => Flyology_SIMD.Backends.Native.Permute_Lanes
           (Value.Low, Value.High,
            Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors)),
         High => Flyology_SIMD.Backends.Native.Permute_Lanes
           (Value.Low, Value.High,
            Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors)));
   end Permute_Lanes;
   function Permute_Lanes
     (Left, Right : U32x8; Map : Two_Source_Lane_Map_32x8) return U32x8
   is
      Left_Low_Selectors : Two_Source_Lane_Selectors_32x4 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_32x4'First)];
      Left_High_Selectors : Two_Source_Lane_Selectors_32x4 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_32x4'First)];
      Right_Low_Selectors : Two_Source_Lane_Selectors_32x4 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_32x4'First)];
      Right_High_Selectors : Two_Source_Lane_Selectors_32x4 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_32x4'First)];
      Low_Right_Bits : Interfaces.Unsigned_8 := 0;
      High_Right_Bits : Interfaces.Unsigned_8 := 0;
   begin
      for Lane in Lane_Index_32x4 loop
         declare
            Low_Selector : constant Two_Source_Lane_Selector_32x8 := Map.Selectors (Lane);
            High_Selector : constant Two_Source_Lane_Selector_32x8 :=
              Map.Selectors (Lane + 4);
         begin
            if Low_Selector.From_Right then
               Right_Low_Selectors (Lane) :=
                 (if Low_Selector.Lane < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_32x4'(Low_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_32x4'(Low_Selector.Lane - 4)));
               Low_Right_Bits := Low_Right_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            else
               Left_Low_Selectors (Lane) :=
                 (if Low_Selector.Lane < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_32x4'(Low_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_32x4'(Low_Selector.Lane - 4)));
            end if;
            if High_Selector.From_Right then
               Right_High_Selectors (Lane) :=
                 (if High_Selector.Lane < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_32x4'(High_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_32x4'(High_Selector.Lane - 4)));
               High_Right_Bits := High_Right_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            else
               Left_High_Selectors (Lane) :=
                 (if High_Selector.Lane < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_32x4'(High_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_32x4'(High_Selector.Lane - 4)));
            end if;
         end;
      end loop;
      declare
         Left_Low : constant U32x4 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Left.Low, Left.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Left_Low_Selectors));
         Left_High : constant U32x4 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Left.Low, Left.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Left_High_Selectors));
         Right_Low : constant U32x4 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Right.Low, Right.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Right_Low_Selectors));
         Right_High : constant U32x4 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Right.Low, Right.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Right_High_Selectors));
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask
                 (Low_Right_Bits), Right_Low, Left_Low),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask
                 (High_Right_Bits), Right_High, Left_High));
      end;
   end Permute_Lanes;
   function Reverse_Lanes (Value : U32x8) return U32x8 is
     (Permute_Lanes
        (Value, (Selectors =>
           [for Lane in Lane_Index_32x8 => 7 - Lane])));
   function Interleave_Low
     (Left, Right : U32x8) return U32x8
   is
      Selectors : constant Two_Source_Lane_Selectors_32x8 :=
        [for Lane in Lane_Index_32x8 => (if Lane mod 2 = 0 then Flyology_SIMD.Wide.Select_Left_Lane (Lane / 2) else Flyology_SIMD.Wide.Select_Right_Lane (Lane / 2))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Interleave_Low;
   function Interleave_High
     (Left, Right : U32x8) return U32x8
   is
      Selectors : constant Two_Source_Lane_Selectors_32x8 :=
        [for Lane in Lane_Index_32x8 => (if Lane mod 2 = 0 then Flyology_SIMD.Wide.Select_Left_Lane (4 + Lane / 2) else Flyology_SIMD.Wide.Select_Right_Lane (4 + Lane / 2))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Interleave_High;
   function Deinterleave_Even
     (Left, Right : U32x8) return U32x8
   is
      Selectors : constant Two_Source_Lane_Selectors_32x8 :=
        [for Lane in Lane_Index_32x8 => (if Lane < 4 then Flyology_SIMD.Wide.Select_Left_Lane (2 * Lane) else Flyology_SIMD.Wide.Select_Right_Lane (2 * (Lane - 4)))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Deinterleave_Even;
   function Deinterleave_Odd
     (Left, Right : U32x8) return U32x8
   is
      Selectors : constant Two_Source_Lane_Selectors_32x8 :=
        [for Lane in Lane_Index_32x8 => (if Lane < 4 then Flyology_SIMD.Wide.Select_Left_Lane (2 * Lane + 1) else Flyology_SIMD.Wide.Select_Right_Lane (2 * (Lane - 4) + 1))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Deinterleave_Odd;
   function Slide_Lanes_Toward_Low
     (Value : U32x8; Count : Natural) return U32x8
   is
      Selectors : Lane_Selectors_32x8 := [others => 0];
      Valid_Bits : Interfaces.Unsigned_8 := 0;
   begin
      if Count < 8 then
         for Lane in Lane_Index_32x8 loop
            if Lane < 8 - Count then
               Selectors (Lane) := Lane + Count;
               Valid_Bits := Valid_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            end if;
         end loop;
      end if;
      declare
         Selected : constant U32x8 :=
           Permute_Lanes (Value, (Selectors => Selectors));
         Zero_Value : constant U32x4 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Valid_Bits),
               Selected.Low, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Shift_Right (Valid_Bits, 4)),
               Selected.High, Zero_Value));
      end;
   end Slide_Lanes_Toward_Low;
   function Slide_Lanes_Toward_High
     (Value : U32x8; Count : Natural) return U32x8
   is
      Selectors : Lane_Selectors_32x8 := [others => 0];
      Valid_Bits : Interfaces.Unsigned_8 := 0;
   begin
      if Count < 8 then
         for Lane in Lane_Index_32x8 loop
            if Lane >= Count then
               Selectors (Lane) := Lane - Count;
               Valid_Bits := Valid_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            end if;
         end loop;
      end if;
      declare
         Selected : constant U32x8 :=
           Permute_Lanes (Value, (Selectors => Selectors));
         Zero_Value : constant U32x4 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Valid_Bits),
               Selected.Low, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Shift_Right (Valid_Bits, 4)),
               Selected.High, Zero_Value));
      end;
   end Slide_Lanes_Toward_High;
   function Permute_Lanes
     (Value : I32x8; Map : Lane_Map_32x8) return I32x8
   is
      Low_Selectors : Two_Source_Lane_Selectors_32x4;
      High_Selectors : Two_Source_Lane_Selectors_32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         declare
            Low_Source : constant Lane_Index_32x8 := Map.Selectors (Lane);
            High_Source : constant Lane_Index_32x8 :=
              Map.Selectors (Lane + 4);
         begin
            Low_Selectors (Lane) :=
              (if Low_Source < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_32x4'(Low_Source))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_32x4'(Low_Source - 4)));
            High_Selectors (Lane) :=
              (if High_Source < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_32x4'(High_Source))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_32x4'(High_Source - 4)));
         end;
      end loop;
      return
        (Low => Flyology_SIMD.Backends.Native.Permute_Lanes
           (Value.Low, Value.High,
            Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors)),
         High => Flyology_SIMD.Backends.Native.Permute_Lanes
           (Value.Low, Value.High,
            Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors)));
   end Permute_Lanes;
   function Permute_Lanes
     (Left, Right : I32x8; Map : Two_Source_Lane_Map_32x8) return I32x8
   is
      Left_Low_Selectors : Two_Source_Lane_Selectors_32x4 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_32x4'First)];
      Left_High_Selectors : Two_Source_Lane_Selectors_32x4 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_32x4'First)];
      Right_Low_Selectors : Two_Source_Lane_Selectors_32x4 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_32x4'First)];
      Right_High_Selectors : Two_Source_Lane_Selectors_32x4 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_32x4'First)];
      Low_Right_Bits : Interfaces.Unsigned_8 := 0;
      High_Right_Bits : Interfaces.Unsigned_8 := 0;
   begin
      for Lane in Lane_Index_32x4 loop
         declare
            Low_Selector : constant Two_Source_Lane_Selector_32x8 := Map.Selectors (Lane);
            High_Selector : constant Two_Source_Lane_Selector_32x8 :=
              Map.Selectors (Lane + 4);
         begin
            if Low_Selector.From_Right then
               Right_Low_Selectors (Lane) :=
                 (if Low_Selector.Lane < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_32x4'(Low_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_32x4'(Low_Selector.Lane - 4)));
               Low_Right_Bits := Low_Right_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            else
               Left_Low_Selectors (Lane) :=
                 (if Low_Selector.Lane < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_32x4'(Low_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_32x4'(Low_Selector.Lane - 4)));
            end if;
            if High_Selector.From_Right then
               Right_High_Selectors (Lane) :=
                 (if High_Selector.Lane < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_32x4'(High_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_32x4'(High_Selector.Lane - 4)));
               High_Right_Bits := High_Right_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            else
               Left_High_Selectors (Lane) :=
                 (if High_Selector.Lane < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_32x4'(High_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_32x4'(High_Selector.Lane - 4)));
            end if;
         end;
      end loop;
      declare
         Left_Low : constant I32x4 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Left.Low, Left.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Left_Low_Selectors));
         Left_High : constant I32x4 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Left.Low, Left.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Left_High_Selectors));
         Right_Low : constant I32x4 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Right.Low, Right.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Right_Low_Selectors));
         Right_High : constant I32x4 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Right.Low, Right.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Right_High_Selectors));
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask
                 (Low_Right_Bits), Right_Low, Left_Low),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask
                 (High_Right_Bits), Right_High, Left_High));
      end;
   end Permute_Lanes;
   function Reverse_Lanes (Value : I32x8) return I32x8 is
     (Permute_Lanes
        (Value, (Selectors =>
           [for Lane in Lane_Index_32x8 => 7 - Lane])));
   function Interleave_Low
     (Left, Right : I32x8) return I32x8
   is
      Selectors : constant Two_Source_Lane_Selectors_32x8 :=
        [for Lane in Lane_Index_32x8 => (if Lane mod 2 = 0 then Flyology_SIMD.Wide.Select_Left_Lane (Lane / 2) else Flyology_SIMD.Wide.Select_Right_Lane (Lane / 2))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Interleave_Low;
   function Interleave_High
     (Left, Right : I32x8) return I32x8
   is
      Selectors : constant Two_Source_Lane_Selectors_32x8 :=
        [for Lane in Lane_Index_32x8 => (if Lane mod 2 = 0 then Flyology_SIMD.Wide.Select_Left_Lane (4 + Lane / 2) else Flyology_SIMD.Wide.Select_Right_Lane (4 + Lane / 2))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Interleave_High;
   function Deinterleave_Even
     (Left, Right : I32x8) return I32x8
   is
      Selectors : constant Two_Source_Lane_Selectors_32x8 :=
        [for Lane in Lane_Index_32x8 => (if Lane < 4 then Flyology_SIMD.Wide.Select_Left_Lane (2 * Lane) else Flyology_SIMD.Wide.Select_Right_Lane (2 * (Lane - 4)))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Deinterleave_Even;
   function Deinterleave_Odd
     (Left, Right : I32x8) return I32x8
   is
      Selectors : constant Two_Source_Lane_Selectors_32x8 :=
        [for Lane in Lane_Index_32x8 => (if Lane < 4 then Flyology_SIMD.Wide.Select_Left_Lane (2 * Lane + 1) else Flyology_SIMD.Wide.Select_Right_Lane (2 * (Lane - 4) + 1))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Deinterleave_Odd;
   function Slide_Lanes_Toward_Low
     (Value : I32x8; Count : Natural) return I32x8
   is
      Selectors : Lane_Selectors_32x8 := [others => 0];
      Valid_Bits : Interfaces.Unsigned_8 := 0;
   begin
      if Count < 8 then
         for Lane in Lane_Index_32x8 loop
            if Lane < 8 - Count then
               Selectors (Lane) := Lane + Count;
               Valid_Bits := Valid_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            end if;
         end loop;
      end if;
      declare
         Selected : constant I32x8 :=
           Permute_Lanes (Value, (Selectors => Selectors));
         Zero_Value : constant I32x4 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Valid_Bits),
               Selected.Low, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Shift_Right (Valid_Bits, 4)),
               Selected.High, Zero_Value));
      end;
   end Slide_Lanes_Toward_Low;
   function Slide_Lanes_Toward_High
     (Value : I32x8; Count : Natural) return I32x8
   is
      Selectors : Lane_Selectors_32x8 := [others => 0];
      Valid_Bits : Interfaces.Unsigned_8 := 0;
   begin
      if Count < 8 then
         for Lane in Lane_Index_32x8 loop
            if Lane >= Count then
               Selectors (Lane) := Lane - Count;
               Valid_Bits := Valid_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            end if;
         end loop;
      end if;
      declare
         Selected : constant I32x8 :=
           Permute_Lanes (Value, (Selectors => Selectors));
         Zero_Value : constant I32x4 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Valid_Bits),
               Selected.Low, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Shift_Right (Valid_Bits, 4)),
               Selected.High, Zero_Value));
      end;
   end Slide_Lanes_Toward_High;
   function Permute_Lanes
     (Value : U64x4; Map : Lane_Map_64x4) return U64x4
   is
      Low_Selectors : Two_Source_Lane_Selectors_64x2;
      High_Selectors : Two_Source_Lane_Selectors_64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         declare
            Low_Source : constant Lane_Index_64x4 := Map.Selectors (Lane);
            High_Source : constant Lane_Index_64x4 :=
              Map.Selectors (Lane + 2);
         begin
            Low_Selectors (Lane) :=
              (if Low_Source < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_64x2'(Low_Source))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_64x2'(Low_Source - 2)));
            High_Selectors (Lane) :=
              (if High_Source < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_64x2'(High_Source))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_64x2'(High_Source - 2)));
         end;
      end loop;
      return
        (Low => Flyology_SIMD.Backends.Native.Permute_Lanes
           (Value.Low, Value.High,
            Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors)),
         High => Flyology_SIMD.Backends.Native.Permute_Lanes
           (Value.Low, Value.High,
            Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors)));
   end Permute_Lanes;
   function Permute_Lanes
     (Left, Right : U64x4; Map : Two_Source_Lane_Map_64x4) return U64x4
   is
      Left_Low_Selectors : Two_Source_Lane_Selectors_64x2 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_64x2'First)];
      Left_High_Selectors : Two_Source_Lane_Selectors_64x2 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_64x2'First)];
      Right_Low_Selectors : Two_Source_Lane_Selectors_64x2 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_64x2'First)];
      Right_High_Selectors : Two_Source_Lane_Selectors_64x2 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_64x2'First)];
      Low_Right_Bits : Interfaces.Unsigned_8 := 0;
      High_Right_Bits : Interfaces.Unsigned_8 := 0;
   begin
      for Lane in Lane_Index_64x2 loop
         declare
            Low_Selector : constant Two_Source_Lane_Selector_64x4 := Map.Selectors (Lane);
            High_Selector : constant Two_Source_Lane_Selector_64x4 :=
              Map.Selectors (Lane + 2);
         begin
            if Low_Selector.From_Right then
               Right_Low_Selectors (Lane) :=
                 (if Low_Selector.Lane < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_64x2'(Low_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_64x2'(Low_Selector.Lane - 2)));
               Low_Right_Bits := Low_Right_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            else
               Left_Low_Selectors (Lane) :=
                 (if Low_Selector.Lane < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_64x2'(Low_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_64x2'(Low_Selector.Lane - 2)));
            end if;
            if High_Selector.From_Right then
               Right_High_Selectors (Lane) :=
                 (if High_Selector.Lane < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_64x2'(High_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_64x2'(High_Selector.Lane - 2)));
               High_Right_Bits := High_Right_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            else
               Left_High_Selectors (Lane) :=
                 (if High_Selector.Lane < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_64x2'(High_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_64x2'(High_Selector.Lane - 2)));
            end if;
         end;
      end loop;
      declare
         Left_Low : constant U64x2 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Left.Low, Left.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Left_Low_Selectors));
         Left_High : constant U64x2 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Left.Low, Left.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Left_High_Selectors));
         Right_Low : constant U64x2 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Right.Low, Right.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Right_Low_Selectors));
         Right_High : constant U64x2 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Right.Low, Right.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Right_High_Selectors));
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask
                 (Low_Right_Bits), Right_Low, Left_Low),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask
                 (High_Right_Bits), Right_High, Left_High));
      end;
   end Permute_Lanes;
   function Reverse_Lanes (Value : U64x4) return U64x4 is
     (Permute_Lanes
        (Value, (Selectors =>
           [for Lane in Lane_Index_64x4 => 3 - Lane])));
   function Interleave_Low
     (Left, Right : U64x4) return U64x4
   is
      Selectors : constant Two_Source_Lane_Selectors_64x4 :=
        [for Lane in Lane_Index_64x4 => (if Lane mod 2 = 0 then Flyology_SIMD.Wide.Select_Left_Lane (Lane / 2) else Flyology_SIMD.Wide.Select_Right_Lane (Lane / 2))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Interleave_Low;
   function Interleave_High
     (Left, Right : U64x4) return U64x4
   is
      Selectors : constant Two_Source_Lane_Selectors_64x4 :=
        [for Lane in Lane_Index_64x4 => (if Lane mod 2 = 0 then Flyology_SIMD.Wide.Select_Left_Lane (2 + Lane / 2) else Flyology_SIMD.Wide.Select_Right_Lane (2 + Lane / 2))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Interleave_High;
   function Deinterleave_Even
     (Left, Right : U64x4) return U64x4
   is
      Selectors : constant Two_Source_Lane_Selectors_64x4 :=
        [for Lane in Lane_Index_64x4 => (if Lane < 2 then Flyology_SIMD.Wide.Select_Left_Lane (2 * Lane) else Flyology_SIMD.Wide.Select_Right_Lane (2 * (Lane - 2)))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Deinterleave_Even;
   function Deinterleave_Odd
     (Left, Right : U64x4) return U64x4
   is
      Selectors : constant Two_Source_Lane_Selectors_64x4 :=
        [for Lane in Lane_Index_64x4 => (if Lane < 2 then Flyology_SIMD.Wide.Select_Left_Lane (2 * Lane + 1) else Flyology_SIMD.Wide.Select_Right_Lane (2 * (Lane - 2) + 1))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Deinterleave_Odd;
   function Slide_Lanes_Toward_Low
     (Value : U64x4; Count : Natural) return U64x4
   is
      Selectors : Lane_Selectors_64x4 := [others => 0];
      Valid_Bits : Interfaces.Unsigned_8 := 0;
   begin
      if Count < 4 then
         for Lane in Lane_Index_64x4 loop
            if Lane < 4 - Count then
               Selectors (Lane) := Lane + Count;
               Valid_Bits := Valid_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            end if;
         end loop;
      end if;
      declare
         Selected : constant U64x4 :=
           Permute_Lanes (Value, (Selectors => Selectors));
         Zero_Value : constant U64x2 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Valid_Bits),
               Selected.Low, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Shift_Right (Valid_Bits, 2)),
               Selected.High, Zero_Value));
      end;
   end Slide_Lanes_Toward_Low;
   function Slide_Lanes_Toward_High
     (Value : U64x4; Count : Natural) return U64x4
   is
      Selectors : Lane_Selectors_64x4 := [others => 0];
      Valid_Bits : Interfaces.Unsigned_8 := 0;
   begin
      if Count < 4 then
         for Lane in Lane_Index_64x4 loop
            if Lane >= Count then
               Selectors (Lane) := Lane - Count;
               Valid_Bits := Valid_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            end if;
         end loop;
      end if;
      declare
         Selected : constant U64x4 :=
           Permute_Lanes (Value, (Selectors => Selectors));
         Zero_Value : constant U64x2 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Valid_Bits),
               Selected.Low, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Shift_Right (Valid_Bits, 2)),
               Selected.High, Zero_Value));
      end;
   end Slide_Lanes_Toward_High;
   function Permute_Lanes
     (Value : I64x4; Map : Lane_Map_64x4) return I64x4
   is
      Low_Selectors : Two_Source_Lane_Selectors_64x2;
      High_Selectors : Two_Source_Lane_Selectors_64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         declare
            Low_Source : constant Lane_Index_64x4 := Map.Selectors (Lane);
            High_Source : constant Lane_Index_64x4 :=
              Map.Selectors (Lane + 2);
         begin
            Low_Selectors (Lane) :=
              (if Low_Source < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_64x2'(Low_Source))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_64x2'(Low_Source - 2)));
            High_Selectors (Lane) :=
              (if High_Source < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_64x2'(High_Source))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_64x2'(High_Source - 2)));
         end;
      end loop;
      return
        (Low => Flyology_SIMD.Backends.Native.Permute_Lanes
           (Value.Low, Value.High,
            Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors)),
         High => Flyology_SIMD.Backends.Native.Permute_Lanes
           (Value.Low, Value.High,
            Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors)));
   end Permute_Lanes;
   function Permute_Lanes
     (Left, Right : I64x4; Map : Two_Source_Lane_Map_64x4) return I64x4
   is
      Left_Low_Selectors : Two_Source_Lane_Selectors_64x2 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_64x2'First)];
      Left_High_Selectors : Two_Source_Lane_Selectors_64x2 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_64x2'First)];
      Right_Low_Selectors : Two_Source_Lane_Selectors_64x2 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_64x2'First)];
      Right_High_Selectors : Two_Source_Lane_Selectors_64x2 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_64x2'First)];
      Low_Right_Bits : Interfaces.Unsigned_8 := 0;
      High_Right_Bits : Interfaces.Unsigned_8 := 0;
   begin
      for Lane in Lane_Index_64x2 loop
         declare
            Low_Selector : constant Two_Source_Lane_Selector_64x4 := Map.Selectors (Lane);
            High_Selector : constant Two_Source_Lane_Selector_64x4 :=
              Map.Selectors (Lane + 2);
         begin
            if Low_Selector.From_Right then
               Right_Low_Selectors (Lane) :=
                 (if Low_Selector.Lane < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_64x2'(Low_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_64x2'(Low_Selector.Lane - 2)));
               Low_Right_Bits := Low_Right_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            else
               Left_Low_Selectors (Lane) :=
                 (if Low_Selector.Lane < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_64x2'(Low_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_64x2'(Low_Selector.Lane - 2)));
            end if;
            if High_Selector.From_Right then
               Right_High_Selectors (Lane) :=
                 (if High_Selector.Lane < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_64x2'(High_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_64x2'(High_Selector.Lane - 2)));
               High_Right_Bits := High_Right_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            else
               Left_High_Selectors (Lane) :=
                 (if High_Selector.Lane < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_64x2'(High_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_64x2'(High_Selector.Lane - 2)));
            end if;
         end;
      end loop;
      declare
         Left_Low : constant I64x2 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Left.Low, Left.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Left_Low_Selectors));
         Left_High : constant I64x2 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Left.Low, Left.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Left_High_Selectors));
         Right_Low : constant I64x2 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Right.Low, Right.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Right_Low_Selectors));
         Right_High : constant I64x2 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Right.Low, Right.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Right_High_Selectors));
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask
                 (Low_Right_Bits), Right_Low, Left_Low),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask
                 (High_Right_Bits), Right_High, Left_High));
      end;
   end Permute_Lanes;
   function Reverse_Lanes (Value : I64x4) return I64x4 is
     (Permute_Lanes
        (Value, (Selectors =>
           [for Lane in Lane_Index_64x4 => 3 - Lane])));
   function Interleave_Low
     (Left, Right : I64x4) return I64x4
   is
      Selectors : constant Two_Source_Lane_Selectors_64x4 :=
        [for Lane in Lane_Index_64x4 => (if Lane mod 2 = 0 then Flyology_SIMD.Wide.Select_Left_Lane (Lane / 2) else Flyology_SIMD.Wide.Select_Right_Lane (Lane / 2))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Interleave_Low;
   function Interleave_High
     (Left, Right : I64x4) return I64x4
   is
      Selectors : constant Two_Source_Lane_Selectors_64x4 :=
        [for Lane in Lane_Index_64x4 => (if Lane mod 2 = 0 then Flyology_SIMD.Wide.Select_Left_Lane (2 + Lane / 2) else Flyology_SIMD.Wide.Select_Right_Lane (2 + Lane / 2))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Interleave_High;
   function Deinterleave_Even
     (Left, Right : I64x4) return I64x4
   is
      Selectors : constant Two_Source_Lane_Selectors_64x4 :=
        [for Lane in Lane_Index_64x4 => (if Lane < 2 then Flyology_SIMD.Wide.Select_Left_Lane (2 * Lane) else Flyology_SIMD.Wide.Select_Right_Lane (2 * (Lane - 2)))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Deinterleave_Even;
   function Deinterleave_Odd
     (Left, Right : I64x4) return I64x4
   is
      Selectors : constant Two_Source_Lane_Selectors_64x4 :=
        [for Lane in Lane_Index_64x4 => (if Lane < 2 then Flyology_SIMD.Wide.Select_Left_Lane (2 * Lane + 1) else Flyology_SIMD.Wide.Select_Right_Lane (2 * (Lane - 2) + 1))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Deinterleave_Odd;
   function Slide_Lanes_Toward_Low
     (Value : I64x4; Count : Natural) return I64x4
   is
      Selectors : Lane_Selectors_64x4 := [others => 0];
      Valid_Bits : Interfaces.Unsigned_8 := 0;
   begin
      if Count < 4 then
         for Lane in Lane_Index_64x4 loop
            if Lane < 4 - Count then
               Selectors (Lane) := Lane + Count;
               Valid_Bits := Valid_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            end if;
         end loop;
      end if;
      declare
         Selected : constant I64x4 :=
           Permute_Lanes (Value, (Selectors => Selectors));
         Zero_Value : constant I64x2 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Valid_Bits),
               Selected.Low, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Shift_Right (Valid_Bits, 2)),
               Selected.High, Zero_Value));
      end;
   end Slide_Lanes_Toward_Low;
   function Slide_Lanes_Toward_High
     (Value : I64x4; Count : Natural) return I64x4
   is
      Selectors : Lane_Selectors_64x4 := [others => 0];
      Valid_Bits : Interfaces.Unsigned_8 := 0;
   begin
      if Count < 4 then
         for Lane in Lane_Index_64x4 loop
            if Lane >= Count then
               Selectors (Lane) := Lane - Count;
               Valid_Bits := Valid_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            end if;
         end loop;
      end if;
      declare
         Selected : constant I64x4 :=
           Permute_Lanes (Value, (Selectors => Selectors));
         Zero_Value : constant I64x2 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Valid_Bits),
               Selected.Low, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Shift_Right (Valid_Bits, 2)),
               Selected.High, Zero_Value));
      end;
   end Slide_Lanes_Toward_High;
   function Permute_Lanes
     (Value : F32x8; Map : Lane_Map_32x8) return F32x8
   is
      Low_Selectors : Two_Source_Lane_Selectors_32x4;
      High_Selectors : Two_Source_Lane_Selectors_32x4;
   begin
      for Lane in Lane_Index_32x4 loop
         declare
            Low_Source : constant Lane_Index_32x8 := Map.Selectors (Lane);
            High_Source : constant Lane_Index_32x8 :=
              Map.Selectors (Lane + 4);
         begin
            Low_Selectors (Lane) :=
              (if Low_Source < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_32x4'(Low_Source))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_32x4'(Low_Source - 4)));
            High_Selectors (Lane) :=
              (if High_Source < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_32x4'(High_Source))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_32x4'(High_Source - 4)));
         end;
      end loop;
      return
        (Low => Flyology_SIMD.Backends.Native.Permute_Lanes
           (Value.Low, Value.High,
            Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors)),
         High => Flyology_SIMD.Backends.Native.Permute_Lanes
           (Value.Low, Value.High,
            Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors)));
   end Permute_Lanes;
   function Permute_Lanes
     (Left, Right : F32x8; Map : Two_Source_Lane_Map_32x8) return F32x8
   is
      Left_Low_Selectors : Two_Source_Lane_Selectors_32x4 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_32x4'First)];
      Left_High_Selectors : Two_Source_Lane_Selectors_32x4 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_32x4'First)];
      Right_Low_Selectors : Two_Source_Lane_Selectors_32x4 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_32x4'First)];
      Right_High_Selectors : Two_Source_Lane_Selectors_32x4 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_32x4'First)];
      Low_Right_Bits : Interfaces.Unsigned_8 := 0;
      High_Right_Bits : Interfaces.Unsigned_8 := 0;
   begin
      for Lane in Lane_Index_32x4 loop
         declare
            Low_Selector : constant Two_Source_Lane_Selector_32x8 := Map.Selectors (Lane);
            High_Selector : constant Two_Source_Lane_Selector_32x8 :=
              Map.Selectors (Lane + 4);
         begin
            if Low_Selector.From_Right then
               Right_Low_Selectors (Lane) :=
                 (if Low_Selector.Lane < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_32x4'(Low_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_32x4'(Low_Selector.Lane - 4)));
               Low_Right_Bits := Low_Right_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            else
               Left_Low_Selectors (Lane) :=
                 (if Low_Selector.Lane < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_32x4'(Low_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_32x4'(Low_Selector.Lane - 4)));
            end if;
            if High_Selector.From_Right then
               Right_High_Selectors (Lane) :=
                 (if High_Selector.Lane < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_32x4'(High_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_32x4'(High_Selector.Lane - 4)));
               High_Right_Bits := High_Right_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            else
               Left_High_Selectors (Lane) :=
                 (if High_Selector.Lane < 4
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_32x4'(High_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_32x4'(High_Selector.Lane - 4)));
            end if;
         end;
      end loop;
      declare
         Left_Low : constant F32x4 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Left.Low, Left.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Left_Low_Selectors));
         Left_High : constant F32x4 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Left.Low, Left.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Left_High_Selectors));
         Right_Low : constant F32x4 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Right.Low, Right.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Right_Low_Selectors));
         Right_High : constant F32x4 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Right.Low, Right.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Right_High_Selectors));
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask
                 (Low_Right_Bits), Right_Low, Left_Low),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask
                 (High_Right_Bits), Right_High, Left_High));
      end;
   end Permute_Lanes;
   function Reverse_Lanes (Value : F32x8) return F32x8 is
     (Permute_Lanes
        (Value, (Selectors =>
           [for Lane in Lane_Index_32x8 => 7 - Lane])));
   function Interleave_Low
     (Left, Right : F32x8) return F32x8
   is
      Selectors : constant Two_Source_Lane_Selectors_32x8 :=
        [for Lane in Lane_Index_32x8 => (if Lane mod 2 = 0 then Flyology_SIMD.Wide.Select_Left_Lane (Lane / 2) else Flyology_SIMD.Wide.Select_Right_Lane (Lane / 2))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Interleave_Low;
   function Interleave_High
     (Left, Right : F32x8) return F32x8
   is
      Selectors : constant Two_Source_Lane_Selectors_32x8 :=
        [for Lane in Lane_Index_32x8 => (if Lane mod 2 = 0 then Flyology_SIMD.Wide.Select_Left_Lane (4 + Lane / 2) else Flyology_SIMD.Wide.Select_Right_Lane (4 + Lane / 2))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Interleave_High;
   function Deinterleave_Even
     (Left, Right : F32x8) return F32x8
   is
      Selectors : constant Two_Source_Lane_Selectors_32x8 :=
        [for Lane in Lane_Index_32x8 => (if Lane < 4 then Flyology_SIMD.Wide.Select_Left_Lane (2 * Lane) else Flyology_SIMD.Wide.Select_Right_Lane (2 * (Lane - 4)))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Deinterleave_Even;
   function Deinterleave_Odd
     (Left, Right : F32x8) return F32x8
   is
      Selectors : constant Two_Source_Lane_Selectors_32x8 :=
        [for Lane in Lane_Index_32x8 => (if Lane < 4 then Flyology_SIMD.Wide.Select_Left_Lane (2 * Lane + 1) else Flyology_SIMD.Wide.Select_Right_Lane (2 * (Lane - 4) + 1))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Deinterleave_Odd;
   function Slide_Lanes_Toward_Low
     (Value : F32x8; Count : Natural) return F32x8
   is
      Selectors : Lane_Selectors_32x8 := [others => 0];
      Valid_Bits : Interfaces.Unsigned_8 := 0;
   begin
      if Count < 8 then
         for Lane in Lane_Index_32x8 loop
            if Lane < 8 - Count then
               Selectors (Lane) := Lane + Count;
               Valid_Bits := Valid_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            end if;
         end loop;
      end if;
      declare
         Selected : constant F32x8 :=
           Permute_Lanes (Value, (Selectors => Selectors));
         Zero_Value : constant F32x4 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Valid_Bits),
               Selected.Low, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Shift_Right (Valid_Bits, 4)),
               Selected.High, Zero_Value));
      end;
   end Slide_Lanes_Toward_Low;
   function Slide_Lanes_Toward_High
     (Value : F32x8; Count : Natural) return F32x8
   is
      Selectors : Lane_Selectors_32x8 := [others => 0];
      Valid_Bits : Interfaces.Unsigned_8 := 0;
   begin
      if Count < 8 then
         for Lane in Lane_Index_32x8 loop
            if Lane >= Count then
               Selectors (Lane) := Lane - Count;
               Valid_Bits := Valid_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            end if;
         end loop;
      end if;
      declare
         Selected : constant F32x8 :=
           Permute_Lanes (Value, (Selectors => Selectors));
         Zero_Value : constant F32x4 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Valid_Bits),
               Selected.Low, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Shift_Right (Valid_Bits, 4)),
               Selected.High, Zero_Value));
      end;
   end Slide_Lanes_Toward_High;
   function Permute_Lanes
     (Value : F64x4; Map : Lane_Map_64x4) return F64x4
   is
      Low_Selectors : Two_Source_Lane_Selectors_64x2;
      High_Selectors : Two_Source_Lane_Selectors_64x2;
   begin
      for Lane in Lane_Index_64x2 loop
         declare
            Low_Source : constant Lane_Index_64x4 := Map.Selectors (Lane);
            High_Source : constant Lane_Index_64x4 :=
              Map.Selectors (Lane + 2);
         begin
            Low_Selectors (Lane) :=
              (if Low_Source < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_64x2'(Low_Source))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_64x2'(Low_Source - 2)));
            High_Selectors (Lane) :=
              (if High_Source < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_64x2'(High_Source))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_64x2'(High_Source - 2)));
         end;
      end loop;
      return
        (Low => Flyology_SIMD.Backends.Native.Permute_Lanes
           (Value.Low, Value.High,
            Flyology_SIMD.Make_Two_Source_Lane_Map (Low_Selectors)),
         High => Flyology_SIMD.Backends.Native.Permute_Lanes
           (Value.Low, Value.High,
            Flyology_SIMD.Make_Two_Source_Lane_Map (High_Selectors)));
   end Permute_Lanes;
   function Permute_Lanes
     (Left, Right : F64x4; Map : Two_Source_Lane_Map_64x4) return F64x4
   is
      Left_Low_Selectors : Two_Source_Lane_Selectors_64x2 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_64x2'First)];
      Left_High_Selectors : Two_Source_Lane_Selectors_64x2 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_64x2'First)];
      Right_Low_Selectors : Two_Source_Lane_Selectors_64x2 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_64x2'First)];
      Right_High_Selectors : Two_Source_Lane_Selectors_64x2 :=
        [others => Flyology_SIMD.Select_Left_Lane (Lane_Index_64x2'First)];
      Low_Right_Bits : Interfaces.Unsigned_8 := 0;
      High_Right_Bits : Interfaces.Unsigned_8 := 0;
   begin
      for Lane in Lane_Index_64x2 loop
         declare
            Low_Selector : constant Two_Source_Lane_Selector_64x4 := Map.Selectors (Lane);
            High_Selector : constant Two_Source_Lane_Selector_64x4 :=
              Map.Selectors (Lane + 2);
         begin
            if Low_Selector.From_Right then
               Right_Low_Selectors (Lane) :=
                 (if Low_Selector.Lane < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_64x2'(Low_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_64x2'(Low_Selector.Lane - 2)));
               Low_Right_Bits := Low_Right_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            else
               Left_Low_Selectors (Lane) :=
                 (if Low_Selector.Lane < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_64x2'(Low_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_64x2'(Low_Selector.Lane - 2)));
            end if;
            if High_Selector.From_Right then
               Right_High_Selectors (Lane) :=
                 (if High_Selector.Lane < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_64x2'(High_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_64x2'(High_Selector.Lane - 2)));
               High_Right_Bits := High_Right_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            else
               Left_High_Selectors (Lane) :=
                 (if High_Selector.Lane < 2
                  then Flyology_SIMD.Select_Left_Lane
                         (Lane_Index_64x2'(High_Selector.Lane))
                  else Flyology_SIMD.Select_Right_Lane
                         (Lane_Index_64x2'(High_Selector.Lane - 2)));
            end if;
         end;
      end loop;
      declare
         Left_Low : constant F64x2 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Left.Low, Left.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Left_Low_Selectors));
         Left_High : constant F64x2 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Left.Low, Left.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Left_High_Selectors));
         Right_Low : constant F64x2 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Right.Low, Right.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Right_Low_Selectors));
         Right_High : constant F64x2 :=
           Flyology_SIMD.Backends.Native.Permute_Lanes
             (Right.Low, Right.High, Flyology_SIMD.Make_Two_Source_Lane_Map
                (Right_High_Selectors));
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask
                 (Low_Right_Bits), Right_Low, Left_Low),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask
                 (High_Right_Bits), Right_High, Left_High));
      end;
   end Permute_Lanes;
   function Reverse_Lanes (Value : F64x4) return F64x4 is
     (Permute_Lanes
        (Value, (Selectors =>
           [for Lane in Lane_Index_64x4 => 3 - Lane])));
   function Interleave_Low
     (Left, Right : F64x4) return F64x4
   is
      Selectors : constant Two_Source_Lane_Selectors_64x4 :=
        [for Lane in Lane_Index_64x4 => (if Lane mod 2 = 0 then Flyology_SIMD.Wide.Select_Left_Lane (Lane / 2) else Flyology_SIMD.Wide.Select_Right_Lane (Lane / 2))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Interleave_Low;
   function Interleave_High
     (Left, Right : F64x4) return F64x4
   is
      Selectors : constant Two_Source_Lane_Selectors_64x4 :=
        [for Lane in Lane_Index_64x4 => (if Lane mod 2 = 0 then Flyology_SIMD.Wide.Select_Left_Lane (2 + Lane / 2) else Flyology_SIMD.Wide.Select_Right_Lane (2 + Lane / 2))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Interleave_High;
   function Deinterleave_Even
     (Left, Right : F64x4) return F64x4
   is
      Selectors : constant Two_Source_Lane_Selectors_64x4 :=
        [for Lane in Lane_Index_64x4 => (if Lane < 2 then Flyology_SIMD.Wide.Select_Left_Lane (2 * Lane) else Flyology_SIMD.Wide.Select_Right_Lane (2 * (Lane - 2)))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Deinterleave_Even;
   function Deinterleave_Odd
     (Left, Right : F64x4) return F64x4
   is
      Selectors : constant Two_Source_Lane_Selectors_64x4 :=
        [for Lane in Lane_Index_64x4 => (if Lane < 2 then Flyology_SIMD.Wide.Select_Left_Lane (2 * Lane + 1) else Flyology_SIMD.Wide.Select_Right_Lane (2 * (Lane - 2) + 1))];
   begin
      return Permute_Lanes
        (Left, Right, (Selectors => Selectors));
   end Deinterleave_Odd;
   function Slide_Lanes_Toward_Low
     (Value : F64x4; Count : Natural) return F64x4
   is
      Selectors : Lane_Selectors_64x4 := [others => 0];
      Valid_Bits : Interfaces.Unsigned_8 := 0;
   begin
      if Count < 4 then
         for Lane in Lane_Index_64x4 loop
            if Lane < 4 - Count then
               Selectors (Lane) := Lane + Count;
               Valid_Bits := Valid_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            end if;
         end loop;
      end if;
      declare
         Selected : constant F64x4 :=
           Permute_Lanes (Value, (Selectors => Selectors));
         Zero_Value : constant F64x2 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Valid_Bits),
               Selected.Low, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Shift_Right (Valid_Bits, 2)),
               Selected.High, Zero_Value));
      end;
   end Slide_Lanes_Toward_Low;
   function Slide_Lanes_Toward_High
     (Value : F64x4; Count : Natural) return F64x4
   is
      Selectors : Lane_Selectors_64x4 := [others => 0];
      Valid_Bits : Interfaces.Unsigned_8 := 0;
   begin
      if Count < 4 then
         for Lane in Lane_Index_64x4 loop
            if Lane >= Count then
               Selectors (Lane) := Lane - Count;
               Valid_Bits := Valid_Bits or Interfaces.Shift_Left
                 (Interfaces.Unsigned_8'(1), Lane);
            end if;
         end loop;
      end if;
      declare
         Selected : constant F64x4 :=
           Permute_Lanes (Value, (Selectors => Selectors));
         Zero_Value : constant F64x2 :=
           Flyology_SIMD.Backends.Native.Zero;
      begin
         return
           (Low => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Valid_Bits),
               Selected.Low, Zero_Value),
            High => Flyology_SIMD.Backends.Native.Select_Value
              (Flyology_SIMD.Backends.Native.Mask_From_Bit_Mask (Interfaces.Shift_Right (Valid_Bits, 2)),
               Selected.High, Zero_Value));
      end;
   end Slide_Lanes_Toward_High;
end Flyology_SIMD.Wide.Permute_Mechanism;
