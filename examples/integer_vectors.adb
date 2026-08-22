with Ada.Text_IO;
with Interfaces;
with Flyology_SIMD;
with Flyology_SIMD.Backends.Native;

procedure Integer_Vectors is
   use Ada.Text_IO;
   use Flyology_SIMD;
   use type Interfaces.Unsigned_16;
   package Native renames Flyology_SIMD.Backends.Native;

   Input                : constant U16x8 := Native.From_Lanes ([65_530, 1, 2, 3, 100, 200, 300, 400]);
   Increment            : constant U16x8 := Native.Splat (10);
   Added                : constant U16x8 := Native.Add_Wrap (Input, Increment);
   Subtracted           : constant U16x8 := Native.Subtract_Wrap (Input, Increment);
   Multiplied           : constant U16x8 := Native.Multiply_Wrap (Input, Increment);
   Saturated_Added      : constant U16x8 := Native.Add_Saturate (Input, Increment);
   Saturated_Subtracted : constant U16x8 := Native.Subtract_Saturate (Input, Increment);
   Large                : constant Mask_16x8 := Native.Greater_Than (Input, Native.Splat (150));
   Flags                : constant U16x8 :=
     Native.From_Lanes ([16#ABF7#, 16#1234#, 16#00AA#, 16#FFFF#, 16#8001#, 16#0102#, 16#5555#, 16#AAAA#]);
   Known                : constant U16x8 := Native.Bitwise_And (Flags, Native.Splat (16#00FF#));
   With_Ready           : constant U16x8 := Native.Bitwise_Or (Known, Native.Splat (16#0100#));
   Toggled              : constant U16x8 := Native.Bitwise_Xor (With_Ready, Native.Splat (16#0003#));
   Cleared              : constant U16x8 :=
     Native.Bitwise_And (Toggled, Native.Bitwise_Not (Native.Splat (16#0004#)));
begin
   pragma Assert (Native.Extract (Added, 0) = 4);
   pragma Assert (Native.Extract (Subtracted, 1) = 65_527);
   pragma Assert (Native.Extract (Multiplied, 0) = 65_476);
   pragma Assert (Native.Extract (Saturated_Added, 0) = U16'Last);
   pragma Assert (Native.Extract (Saturated_Subtracted, 1) = 0);
   pragma Assert (Native.Extract (Known, 0) = 16#00F7#);
   pragma Assert (Native.Extract (With_Ready, 0) = 16#01F7#);
   pragma Assert (Native.Extract (Toggled, 0) = 16#01F4#);
   pragma Assert (Native.Extract (Cleared, 0) = 16#01F0#);

   Put_Line ("added lane 0:      " & U16'Image (Native.Extract (Added, 0)));
   Put_Line ("subtracted lane 1: " & U16'Image (Native.Extract (Subtracted, 1)));
   Put_Line ("multiplied lane 0: " & U16'Image (Native.Extract (Multiplied, 0)));
   Put_Line ("saturated add lane 0: " & U16'Image (Native.Extract (Saturated_Added, 0)));
   Put_Line ("saturated subtract lane 1: " & U16'Image (Native.Extract (Saturated_Subtracted, 1)));
   Put_Line ("compact mask:      " & Interfaces.Unsigned_8'Image (Native.To_Bit_Mask (Large)));
   Put_Line ("masked flags lane 0:" & U16'Image (Native.Extract (Known, 0)));
   Put_Line ("updated flags lane 0:" & U16'Image (Native.Extract (Cleared, 0)));
end Integer_Vectors;
