package body Conversion_Test_Floating_Control is
   function Supported return Boolean is (False);

   function Current return Control_Word is (0);

   procedure Set_Rounding_Mode (Mode : Rounding_Mode) is
      pragma Unreferenced (Mode);
   begin
      null;
   end Set_Rounding_Mode;

   procedure Restore (Value : Control_Word) is
      pragma Unreferenced (Value);
   begin
      null;
   end Restore;
end Conversion_Test_Floating_Control;
