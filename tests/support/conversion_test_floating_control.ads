with Interfaces;

package Conversion_Test_Floating_Control is
   type Rounding_Mode is
     (Round_To_Nearest, Round_Down, Round_Up, Round_Toward_Zero);

   subtype Control_Word is Interfaces.Unsigned_32;

   function Supported return Boolean;
   function Current return Control_Word;
   procedure Set_Rounding_Mode (Mode : Rounding_Mode);
   procedure Restore (Value : Control_Word);
end Conversion_Test_Floating_Control;
