with System;
with System.Machine_Code;

package body Conversion_Test_Floating_Control is
   use System.Machine_Code;
   use type Control_Word;

   Rounding_Mask : constant Control_Word := 16#0000_6000#;

   function Supported return Boolean is (True);

   function Current return Control_Word is
      Value : aliased Control_Word;
   begin
      Asm
        (Template => "stmxcsr (%0)",
         Inputs => System.Address'Asm_Input ("r", Value'Address),
         Clobber => "memory",
         Volatile => True);
      return Value;
   end Current;

   procedure Write (Value : Control_Word) is
      Local : aliased constant Control_Word := Value;
   begin
      Asm
        (Template => "ldmxcsr (%0)",
         Inputs => System.Address'Asm_Input ("r", Local'Address),
         Clobber => "memory",
         Volatile => True);
   end Write;

   procedure Set_Rounding_Mode (Mode : Rounding_Mode) is
      Mode_Bits : constant Control_Word :=
        (case Mode is
            when Round_To_Nearest  => 16#0000_0000#,
            when Round_Down        => 16#0000_2000#,
            when Round_Up          => 16#0000_4000#,
            when Round_Toward_Zero => 16#0000_6000#);
   begin
      Write ((Current and not Rounding_Mask) or Mode_Bits);
   end Set_Rounding_Mode;

   procedure Restore (Value : Control_Word) is
   begin
      Write (Value);
   end Restore;
end Conversion_Test_Floating_Control;
