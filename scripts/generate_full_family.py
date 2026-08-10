#!/usr/bin/env python3
"""Generate the repetitive scalar 128-bit family from one type matrix."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC = ROOT / "src" / "flyology_simd.ads"
BODY = ROOT / "src" / "flyology_simd.adb"

INTEGER_TYPES = [
    ("I8x16", "I8", 8, 16, True),
    ("U16x8", "U16", 16, 8, False),
    ("I16x8", "I16", 16, 8, True),
    ("U32x4", "U32", 32, 4, False),
    ("I32x4", "I32", 32, 4, True),
    ("U64x2", "U64", 64, 2, False),
    ("I64x2", "I64", 64, 2, True),
]
FLOAT_TYPES = [
    ("F32x4", "F32", 32, 4),
    ("F64x2", "F64", 64, 2),
]
MASKS = [(16, 8, "Unsigned_8"), (32, 4, "Unsigned_8"), (64, 2, "Unsigned_8")]


def replace_block(text: str, label: str, generated: str) -> str:
    begin = f"   --  BEGIN {label}"
    end = f"   --  END {label}"
    before, remainder = text.split(begin, 1)
    _, after = remainder.split(end, 1)
    return before + begin + "\n" + generated.rstrip() + "\n" + end + after


def mask_for(bits: int, lanes: int) -> str:
    return f"Mask_{bits}x{lanes}"


def lane_index(bits: int, lanes: int) -> str:
    return f"Lane_Index_{bits}x{lanes}"


def lane_count(bits: int, lanes: int) -> str:
    return f"Lane_Count_{bits}x{lanes}"


def lane_values(vector: str) -> str:
    return f"Lane_Values_{vector}"


def array_name(scalar: str) -> str:
    return f"{scalar}_Array"


def emit_spec() -> str:
    out = []
    out += [
        "   subtype I8 is Interfaces.Integer_8;",
        "   subtype U16 is Interfaces.Unsigned_16;",
        "   subtype I16 is Interfaces.Integer_16;",
        "   subtype U32 is Interfaces.Unsigned_32;",
        "   subtype I32 is Interfaces.Integer_32;",
        "   subtype U64 is Interfaces.Unsigned_64;",
        "   subtype I64 is Interfaces.Integer_64;",
        "   subtype F32 is Interfaces.IEEE_Float_32;",
        "   subtype F64 is Interfaces.IEEE_Float_64;",
        "",
    ]
    seen_shapes = {(8, 16)}
    for vector, scalar, bits, lanes, *_ in INTEGER_TYPES + FLOAT_TYPES:
        shape = (bits, lanes)
        if shape not in seen_shapes:
            out += [
                f"   subtype {lane_index(bits, lanes)} is Natural range 0 .. {lanes - 1};",
                f"   subtype {lane_count(bits, lanes)} is Natural range 0 .. {lanes};",
            ]
            seen_shapes.add(shape)
        out += [
            f"   type {lane_values(vector)} is array ({lane_index(bits, lanes)}) of {scalar};",
            f"   type {array_name(scalar)} is array (Natural range <>) of aliased {scalar};",
            f"   type {vector} is private;",
            "",
        ]
    for bits, lanes, _ in MASKS:
        out.append(f"   type {mask_for(bits, lanes)} is private;")
    out.append("")

    for vector, scalar, bits, lanes, signed in INTEGER_TYPES:
        mask = mask_for(bits, lanes)
        idx = lane_index(bits, lanes)
        vals = lane_values(vector)
        count = lane_count(bits, lanes)
        arr = array_name(scalar)
        extent = f"Start in Data'Range and then {lanes - 1} <= Natural (Data'Last - Start)"
        partial = "Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start))"
        out += [
            f"   function Zero return {vector};",
            f"   function Splat (Value : {scalar}) return {vector};",
            f"   function From_Lanes (Values : {vals}) return {vector};",
            f"   function To_Lanes (Value : {vector}) return {vals};",
            f"   function Extract (Value : {vector}; Lane : {idx}) return {scalar};",
            f"   function Replace (Value : {vector}; Lane : {idx}; With_Value : {scalar}) return {vector};",
            f"   function Add_Wrap (Left, Right : {vector}) return {vector};",
            f"   function Subtract_Wrap (Left, Right : {vector}) return {vector};",
            f"   function Multiply_Wrap (Left, Right : {vector}) return {vector};",
            f"   function Add_Saturate (Left, Right : {vector}) return {vector};",
            f"   function Subtract_Saturate (Left, Right : {vector}) return {vector};",
            f"   function Bitwise_And (Left, Right : {vector}) return {vector};",
            f"   function Bitwise_Or (Left, Right : {vector}) return {vector};",
            f"   function Bitwise_Xor (Left, Right : {vector}) return {vector};",
            f"   function Bitwise_Not (Value : {vector}) return {vector};",
            f"   function Shift_Left_Logical (Value : {vector}; Count : Natural) return {vector};",
            f"   function Shift_Right_Logical (Value : {vector}; Count : Natural) return {vector};",
        ]
        if signed:
            out.append(f"   function Shift_Right_Arithmetic (Value : {vector}; Count : Natural) return {vector};")
        out += [
            f"   function Equal (Left, Right : {vector}) return {mask};",
            f"   function Less_Than (Left, Right : {vector}) return {mask};",
            f"   function Less_Equal (Left, Right : {vector}) return {mask};",
            f"   function Greater_Than (Left, Right : {vector}) return {mask};",
            f"   function Greater_Equal (Left, Right : {vector}) return {mask};",
            f"   function Select_Value (Mask : {mask}; If_True, If_False : {vector}) return {vector};",
            f"   function Min (Left, Right : {vector}) return {vector};",
            f"   function Max (Left, Right : {vector}) return {vector};",
            f"   function Reduce_Add_Wrap (Value : {vector}) return {scalar};",
            f"   function Reduce_Min (Value : {vector}) return {scalar};",
            f"   function Reduce_Max (Value : {vector}) return {scalar};",
            f"   function Reverse_Lanes (Value : {vector}) return {vector};",
            f"   function Interleave_Low (Left, Right : {vector}) return {vector};",
            f"   function Interleave_High (Left, Right : {vector}) return {vector};",
            f"   function Is_Aligned_16 (Data : {arr}; Start : Natural) return Boolean;",
            f"   function Load (Data : {arr}; Start : Natural) return {vector}",
            f"     with Pre => {extent};",
            f"   procedure Store (Data : in out {arr}; Start : Natural; Value : {vector}) with Pre => {extent};",
            f"   function Load_Unaligned (Data : {arr}; Start : Natural) return {vector} with Pre => {extent};",
            f"   procedure Store_Unaligned (Data : in out {arr}; Start : Natural; Value : {vector}) with Pre => {extent};",
            f"   function Load_Aligned (Data : {arr}; Start : Natural) return {vector} with Pre => {extent} and then Is_Aligned_16 (Data, Start);",
            f"   procedure Store_Aligned (Data : in out {arr}; Start : Natural; Value : {vector}) with Pre => {extent} and then Is_Aligned_16 (Data, Start);",
            f"   function Load_Partial (Data : {arr}; Start : Natural; Count : {count}) return {vector} with Pre => {partial};",
            f"   procedure Store_Partial (Data : in out {arr}; Start : Natural; Count : {count}; Value : {vector}) with Pre => {partial};",
            "",
        ]

    for vector, scalar, bits, lanes in FLOAT_TYPES:
        mask = mask_for(bits, lanes)
        idx = lane_index(bits, lanes)
        vals = lane_values(vector)
        count = lane_count(bits, lanes)
        arr = array_name(scalar)
        extent = f"Start in Data'Range and then {lanes - 1} <= Natural (Data'Last - Start)"
        partial = "Count = 0 or else (Start in Data'Range and then Count - 1 <= Natural (Data'Last - Start))"
        out += [
            f"   function Zero return {vector};",
            f"   function Splat (Value : {scalar}) return {vector};",
            f"   function From_Lanes (Values : {vals}) return {vector};",
            f"   function To_Lanes (Value : {vector}) return {vals};",
            f"   function Extract (Value : {vector}; Lane : {idx}) return {scalar};",
            f"   function Replace (Value : {vector}; Lane : {idx}; With_Value : {scalar}) return {vector};",
            f"   function Add (Left, Right : {vector}) return {vector};",
            f"   function Subtract (Left, Right : {vector}) return {vector};",
            f"   function Multiply (Left, Right : {vector}) return {vector};",
            f"   function Divide (Left, Right : {vector}) return {vector};",
            f"   function Equal (Left, Right : {vector}) return {mask};",
            f"   function Less_Than (Left, Right : {vector}) return {mask};",
            f"   function Less_Equal (Left, Right : {vector}) return {mask};",
            f"   function Greater_Than (Left, Right : {vector}) return {mask};",
            f"   function Greater_Equal (Left, Right : {vector}) return {mask};",
            f"   function Unordered (Left, Right : {vector}) return {mask};",
            f"   function Select_Value (Mask : {mask}; If_True, If_False : {vector}) return {vector};",
            f"   function Min_Number (Left, Right : {vector}) return {vector};",
            f"   function Max_Number (Left, Right : {vector}) return {vector};",
            f"   function Reduce_Add (Value : {vector}) return {scalar};",
            f"   function Reverse_Lanes (Value : {vector}) return {vector};",
            f"   function Interleave_Low (Left, Right : {vector}) return {vector};",
            f"   function Interleave_High (Left, Right : {vector}) return {vector};",
            f"   function Is_Aligned_16 (Data : {arr}; Start : Natural) return Boolean;",
            f"   function Load (Data : {arr}; Start : Natural) return {vector} with Pre => {extent};",
            f"   procedure Store (Data : in out {arr}; Start : Natural; Value : {vector}) with Pre => {extent};",
            f"   function Load_Unaligned (Data : {arr}; Start : Natural) return {vector} with Pre => {extent};",
            f"   procedure Store_Unaligned (Data : in out {arr}; Start : Natural; Value : {vector}) with Pre => {extent};",
            f"   function Load_Aligned (Data : {arr}; Start : Natural) return {vector} with Pre => {extent} and then Is_Aligned_16 (Data, Start);",
            f"   procedure Store_Aligned (Data : in out {arr}; Start : Natural; Value : {vector}) with Pre => {extent} and then Is_Aligned_16 (Data, Start);",
            f"   function Load_Partial (Data : {arr}; Start : Natural; Count : {count}) return {vector} with Pre => {partial};",
            f"   procedure Store_Partial (Data : in out {arr}; Start : Natural; Count : {count}; Value : {vector}) with Pre => {partial};",
            "",
        ]

    for bits, lanes, storage in MASKS:
        mask = mask_for(bits, lanes)
        idx = lane_index(bits, lanes)
        count = lane_count(bits, lanes)
        out += [
            f"   function Mask_From_Bit_Mask (Bits : Interfaces.{storage}) return {mask};",
            f"   function To_Bit_Mask (Mask : {mask}) return Interfaces.{storage};",
            f"   function Test (Mask : {mask}; Lane : {idx}) return Boolean;",
            f"   function Any_True (Mask : {mask}) return Boolean;",
            f"   function All_True (Mask : {mask}) return Boolean;",
            f"   function None_True (Mask : {mask}) return Boolean;",
            f"   function Population_Count (Mask : {mask}) return {count};",
            "",
        ]
    return "\n".join(out)


def emit_private() -> str:
    out = []
    for vector, _, _, _, *_ in INTEGER_TYPES + FLOAT_TYPES:
        out += [
            f"   type {vector} is record",
            f"      Lanes : {lane_values(vector)};",
            "   end record;",
            f"   for {vector}'Size use 128;",
            "",
        ]
    for bits, lanes, storage in MASKS:
        mask = mask_for(bits, lanes)
        out += [
            f"   type {mask} is record",
            f"      Bits : Interfaces.{storage};",
            "   end record;",
            f"   for {mask}'Size use 8;",
            "",
        ]
    return "\n".join(out)


def signed_unsigned(bits: int) -> str:
    return f"U{bits}"


def emit_integer_body(vector: str, scalar: str, bits: int, lanes: int, signed: bool) -> list[str]:
    idx = lane_index(bits, lanes)
    vals = lane_values(vector)
    mask = mask_for(bits, lanes)
    count = lane_count(bits, lanes)
    arr = array_name(scalar)
    storage = "Interfaces.Unsigned_16" if lanes == 16 else "Interfaces.Unsigned_8"
    all_bits = "Interfaces.Unsigned_16'Last" if lanes == 16 else str((1 << lanes) - 1)
    out = []
    if signed:
        unsigned = signed_unsigned(bits)
        out += [
            f"   function To_{unsigned} is new Ada.Unchecked_Conversion ({scalar}, {unsigned});",
            f"   function To_{scalar} is new Ada.Unchecked_Conversion ({unsigned}, {scalar});",
            "",
        ]
    out += [
        f"   function Zero return {vector} is (Lanes => [others => 0]);",
        f"   function Splat (Value : {scalar}) return {vector} is (Lanes => [others => Value]);",
        f"   function From_Lanes (Values : {vals}) return {vector} is (Lanes => Values);",
        f"   function To_Lanes (Value : {vector}) return {vals} is (Value.Lanes);",
        f"   function Extract (Value : {vector}; Lane : {idx}) return {scalar} is (Value.Lanes (Lane));",
        f"   function Replace (Value : {vector}; Lane : {idx}; With_Value : {scalar}) return {vector} is",
        f"      Result : {vector} := Value;",
        "   begin",
        "      Result.Lanes (Lane) := With_Value;",
        "      return Result;",
        "   end Replace;",
        "",
    ]
    for name, op in (("Add_Wrap", "+"), ("Subtract_Wrap", "-")):
        expr = f"Left.Lanes (Lane) {op} Right.Lanes (Lane)"
        if signed:
            expr = f"To_{scalar} (To_{signed_unsigned(bits)} (Left.Lanes (Lane)) {op} To_{signed_unsigned(bits)} (Right.Lanes (Lane)))"
        out += [
            f"   function {name} (Left, Right : {vector}) return {vector} is",
            f"      Result : {vector};",
            "   begin",
            f"      for Lane in {idx} loop",
            f"         Result.Lanes (Lane) := {expr};",
            "      end loop;",
            "      return Result;",
            f"   end {name};",
            "",
        ]
    out += [
        f"   function Multiply_Wrap (Left, Right : {vector}) return {vector} is",
        f"      Result : {vector};",
        "   begin",
        f"      for Lane in {idx} loop",
        f"         Result.Lanes (Lane) := " +
        (f"To_{scalar} (To_{signed_unsigned(bits)} (Left.Lanes (Lane)) * To_{signed_unsigned(bits)} (Right.Lanes (Lane)));" if signed else "Left.Lanes (Lane) * Right.Lanes (Lane);"),
        "      end loop;",
        "      return Result;",
        "   end Multiply_Wrap;",
        "",
    ]
    out += [
        f"   function Add_Saturate (Left, Right : {vector}) return {vector} is",
        f"      Result : {vector};",
        "   begin",
        f"      for Lane in {idx} loop",
    ]
    if signed:
        out += [
            f"         if Right.Lanes (Lane) > 0 and then Left.Lanes (Lane) > {scalar}'Last - Right.Lanes (Lane) then",
            f"            Result.Lanes (Lane) := {scalar}'Last;",
            f"         elsif Right.Lanes (Lane) < 0 and then Left.Lanes (Lane) < {scalar}'First - Right.Lanes (Lane) then",
            f"            Result.Lanes (Lane) := {scalar}'First;",
            "         else",
            "            Result.Lanes (Lane) := Left.Lanes (Lane) + Right.Lanes (Lane);",
            "         end if;",
        ]
    else:
        out += [
            f"         Result.Lanes (Lane) := (if Left.Lanes (Lane) > {scalar}'Last - Right.Lanes (Lane) then {scalar}'Last else Left.Lanes (Lane) + Right.Lanes (Lane));",
        ]
    out += ["      end loop;", "      return Result;", "   end Add_Saturate;", ""]
    out += [
        f"   function Subtract_Saturate (Left, Right : {vector}) return {vector} is",
        f"      Result : {vector};",
        "   begin",
        f"      for Lane in {idx} loop",
    ]
    if signed:
        out += [
            f"         if Right.Lanes (Lane) < 0 and then Left.Lanes (Lane) > {scalar}'Last + Right.Lanes (Lane) then",
            f"            Result.Lanes (Lane) := {scalar}'Last;",
            f"         elsif Right.Lanes (Lane) > 0 and then Left.Lanes (Lane) < {scalar}'First + Right.Lanes (Lane) then",
            f"            Result.Lanes (Lane) := {scalar}'First;",
            "         else",
            "            Result.Lanes (Lane) := Left.Lanes (Lane) - Right.Lanes (Lane);",
            "         end if;",
        ]
    else:
        out += ["         Result.Lanes (Lane) := (if Left.Lanes (Lane) < Right.Lanes (Lane) then 0 else Left.Lanes (Lane) - Right.Lanes (Lane));"]
    out += ["      end loop;", "      return Result;", "   end Subtract_Saturate;", ""]
    for name, op in (("Bitwise_And", "and"), ("Bitwise_Or", "or"), ("Bitwise_Xor", "xor")):
        expr = f"Left.Lanes (Lane) {op} Right.Lanes (Lane)"
        if signed:
            expr = f"To_{scalar} (To_{signed_unsigned(bits)} (Left.Lanes (Lane)) {op} To_{signed_unsigned(bits)} (Right.Lanes (Lane)))"
        out += [f"   function {name} (Left, Right : {vector}) return {vector} is", f"      Result : {vector};", "   begin", f"      for Lane in {idx} loop", f"         Result.Lanes (Lane) := {expr};", "      end loop;", "      return Result;", f"   end {name};", ""]
    not_expr = "not Value.Lanes (Lane)" if not signed else f"To_{scalar} (not To_{signed_unsigned(bits)} (Value.Lanes (Lane)))"
    out += [f"   function Bitwise_Not (Value : {vector}) return {vector} is", f"      Result : {vector};", "   begin", f"      for Lane in {idx} loop", f"         Result.Lanes (Lane) := {not_expr};", "      end loop;", "      return Result;", "   end Bitwise_Not;", ""]
    for name, shift in (("Shift_Left_Logical", "Shift_Left"), ("Shift_Right_Logical", "Shift_Right")):
        base = f"Value.Lanes (Lane)" if not signed else f"To_{signed_unsigned(bits)} (Value.Lanes (Lane))"
        expr = f"Interfaces.{shift} ({base}, Count)"
        if signed:
            expr = f"To_{scalar} ({expr})"
        out += [f"   function {name} (Value : {vector}; Count : Natural) return {vector} is", f"      Result : {vector};", "   begin", f"      if Count >= {bits} then return Zero; end if;", f"      for Lane in {idx} loop", f"         Result.Lanes (Lane) := {expr};", "      end loop;", "      return Result;", f"   end {name};", ""]
    if signed:
        out += [f"   function Shift_Right_Arithmetic (Value : {vector}; Count : Natural) return {vector} is", f"      Result : {vector};", "   begin", f"      if Count >= {bits} then", f"         for Lane in {idx} loop Result.Lanes (Lane) := (if Value.Lanes (Lane) < 0 then -1 else 0); end loop;", "         return Result;", "      end if;", f"      for Lane in {idx} loop", f"         Result.Lanes (Lane) := To_{scalar} (Interfaces.Shift_Right_Arithmetic (To_{signed_unsigned(bits)} (Value.Lanes (Lane)), Count));", "      end loop;", "      return Result;", "   end Shift_Right_Arithmetic;", ""]
    out += [
        f"   function Compare_{vector} (Left, Right : {vector}; Kind : Character) return {mask} is",
        f"      Bits : {storage} := 0;",
        "      Truth : Boolean;",
        "   begin",
        f"      for Lane in {idx} loop",
        "         case Kind is",
        "            when '=' => Truth := Left.Lanes (Lane) = Right.Lanes (Lane);",
        "            when '<' => Truth := Left.Lanes (Lane) < Right.Lanes (Lane);",
        "            when 'L' => Truth := Left.Lanes (Lane) <= Right.Lanes (Lane);",
        "            when '>' => Truth := Left.Lanes (Lane) > Right.Lanes (Lane);",
        "            when others => Truth := Left.Lanes (Lane) >= Right.Lanes (Lane);",
        "         end case;",
        f"         if Truth then Bits := Bits or Interfaces.Shift_Left ({storage}'(1), Lane); end if;",
        "      end loop;",
        "      return (Bits => Bits);",
        f"   end Compare_{vector};",
    ]
    for name, kind in (("Equal", "="), ("Less_Than", "<"), ("Less_Equal", "L"), ("Greater_Than", ">"), ("Greater_Equal", "G")):
        out.append(f"   function {name} (Left, Right : {vector}) return {mask} is (Compare_{vector} (Left, Right, '{kind}'));")
    out += [
        f"   function Select_Value (Mask : {mask}; If_True, If_False : {vector}) return {vector} is",
        f"      Result : {vector};",
        "   begin",
        f"      for Lane in {idx} loop Result.Lanes (Lane) := (if Test (Mask, Lane) then If_True.Lanes (Lane) else If_False.Lanes (Lane)); end loop;",
        "      return Result;",
        "   end Select_Value;",
    ]
    for name, attr in (("Min", "Min"), ("Max", "Max")):
        out += [f"   function {name} (Left, Right : {vector}) return {vector} is", f"      Result : {vector};", "   begin", f"      for Lane in {idx} loop Result.Lanes (Lane) := {scalar}'{attr} (Left.Lanes (Lane), Right.Lanes (Lane)); end loop;", "      return Result;", f"   end {name};"]
    add_expr = "Result + Value.Lanes (Lane)"
    if signed:
        add_expr = f"To_{scalar} (To_{signed_unsigned(bits)} (Result) + To_{signed_unsigned(bits)} (Value.Lanes (Lane)))"
    out += [f"   function Reduce_Add_Wrap (Value : {vector}) return {scalar} is", f"      Result : {scalar} := 0;", "   begin", f"      for Lane in {idx} loop Result := {add_expr}; end loop;", "      return Result;", "   end Reduce_Add_Wrap;", f"   function Reduce_Min (Value : {vector}) return {scalar} is", "      Result : " + scalar + " := Value.Lanes (0);", "   begin", f"      for Lane in {idx} range 1 .. {lanes - 1} loop Result := {scalar}'Min (Result, Value.Lanes (Lane)); end loop;", "      return Result;", "   end Reduce_Min;", f"   function Reduce_Max (Value : {vector}) return {scalar} is", "      Result : " + scalar + " := Value.Lanes (0);", "   begin", f"      for Lane in {idx} range 1 .. {lanes - 1} loop Result := {scalar}'Max (Result, Value.Lanes (Lane)); end loop;", "      return Result;", "   end Reduce_Max;", ""]
    out += [f"   function Reverse_Lanes (Value : {vector}) return {vector} is", f"      Result : {vector};", "   begin", f"      for Lane in {idx} loop Result.Lanes (Lane) := Value.Lanes ({lanes - 1} - Lane); end loop;", "      return Result;", "   end Reverse_Lanes;"]
    for name, offset in (("Interleave_Low", 0), ("Interleave_High", lanes // 2)):
        out += [f"   function {name} (Left, Right : {vector}) return {vector} is", f"      Result : {vector};", "   begin", f"      for Lane in Natural range 0 .. {lanes // 2 - 1} loop", f"         Result.Lanes (2 * Lane) := Left.Lanes (Lane + {offset});", f"         Result.Lanes (2 * Lane + 1) := Right.Lanes (Lane + {offset});", "      end loop;", "      return Result;", f"   end {name};"]
    out += [f"   function Is_Aligned_16 (Data : {arr}; Start : Natural) return Boolean is (Start in Data'Range and then System.Storage_Elements.To_Integer (Data (Start)'Address) mod 16 = 0);", f"   function Load (Data : {arr}; Start : Natural) return {vector} is (Load_Unaligned (Data, Start));", f"   procedure Store (Data : in out {arr}; Start : Natural; Value : {vector}) is begin Store_Unaligned (Data, Start, Value); end Store;", f"   function Load_Unaligned (Data : {arr}; Start : Natural) return {vector} is", f"      Result : {vector};", "   begin", f"      for Lane in {idx} loop Result.Lanes (Lane) := Data (Start + Lane); end loop;", "      return Result;", "   end Load_Unaligned;", f"   procedure Store_Unaligned (Data : in out {arr}; Start : Natural; Value : {vector}) is", "   begin", f"      for Lane in {idx} loop Data (Start + Lane) := Value.Lanes (Lane); end loop;", "   end Store_Unaligned;", f"   function Load_Aligned (Data : {arr}; Start : Natural) return {vector} is (Load_Unaligned (Data, Start));", f"   procedure Store_Aligned (Data : in out {arr}; Start : Natural; Value : {vector}) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;", f"   function Load_Partial (Data : {arr}; Start : Natural; Count : {count}) return {vector} is", "      Result : " + vector + " := Zero;", "   begin", "      if Count > 0 then for Lane in Natural range 0 .. Count - 1 loop Result.Lanes (Lane) := Data (Start + Lane); end loop; end if;", "      return Result;", "   end Load_Partial;", f"   procedure Store_Partial (Data : in out {arr}; Start : Natural; Count : {count}; Value : {vector}) is", "   begin", "      if Count > 0 then for Lane in Natural range 0 .. Count - 1 loop Data (Start + Lane) := Value.Lanes (Lane); end loop; end if;", "   end Store_Partial;", ""]
    return out


def emit_float_body(vector: str, scalar: str, bits: int, lanes: int) -> list[str]:
    idx = lane_index(bits, lanes)
    vals = lane_values(vector)
    mask = mask_for(bits, lanes)
    count = lane_count(bits, lanes)
    arr = array_name(scalar)
    storage = "Interfaces.Unsigned_8"
    uint = f"U{bits}"
    sign = f"2 ** {bits - 1}"
    out = [f"   function Bits_Of_{scalar} is new Ada.Unchecked_Conversion ({scalar}, {uint});", f"   function Zero return {vector} is (Lanes => [others => 0.0]);", f"   function Splat (Value : {scalar}) return {vector} is (Lanes => [others => Value]);", f"   function From_Lanes (Values : {vals}) return {vector} is (Lanes => Values);", f"   function To_Lanes (Value : {vector}) return {vals} is (Value.Lanes);", f"   function Extract (Value : {vector}; Lane : {idx}) return {scalar} is (Value.Lanes (Lane));", f"   function Replace (Value : {vector}; Lane : {idx}; With_Value : {scalar}) return {vector} is", f"      Result : {vector} := Value;", "   begin Result.Lanes (Lane) := With_Value; return Result; end Replace;"]
    for name, op in (("Add", "+"), ("Subtract", "-"), ("Multiply", "*"), ("Divide", "/")):
        out += [f"   function {name} (Left, Right : {vector}) return {vector} is", f"      Result : {vector};", "   begin", f"      for Lane in {idx} loop Result.Lanes (Lane) := Left.Lanes (Lane) {op} Right.Lanes (Lane); end loop;", "      return Result;", f"   end {name};"]
    out += [f"   function Compare_{vector} (Left, Right : {vector}; Kind : Character) return {mask} is", f"      Bits : {storage} := 0;", "      Truth : Boolean;", "   begin", f"      for Lane in {idx} loop", "         case Kind is", "            when '=' => Truth := Left.Lanes (Lane) = Right.Lanes (Lane);", "            when '<' => Truth := Left.Lanes (Lane) < Right.Lanes (Lane);", "            when 'L' => Truth := Left.Lanes (Lane) <= Right.Lanes (Lane);", "            when '>' => Truth := Left.Lanes (Lane) > Right.Lanes (Lane);", "            when 'G' => Truth := Left.Lanes (Lane) >= Right.Lanes (Lane);", "            when others => Truth := Left.Lanes (Lane) /= Left.Lanes (Lane) or else Right.Lanes (Lane) /= Right.Lanes (Lane);", "         end case;", f"         if Truth then Bits := Bits or Interfaces.Shift_Left ({storage}'(1), Lane); end if;", "      end loop;", "      return (Bits => Bits);", f"   end Compare_{vector};"]
    for name, kind in (("Equal", "="), ("Less_Than", "<"), ("Less_Equal", "L"), ("Greater_Than", ">"), ("Greater_Equal", "G"), ("Unordered", "U")):
        out.append(f"   function {name} (Left, Right : {vector}) return {mask} is (Compare_{vector} (Left, Right, '{kind}'));")
    out += [f"   function Select_Value (Mask : {mask}; If_True, If_False : {vector}) return {vector} is", f"      Result : {vector};", "   begin", f"      for Lane in {idx} loop Result.Lanes (Lane) := (if Test (Mask, Lane) then If_True.Lanes (Lane) else If_False.Lanes (Lane)); end loop;", "      return Result;", "   end Select_Value;"]
    for name, choose in (("Min_Number", "<"), ("Max_Number", ">")):
        zero_choice = (f"(if (Bits_Of_{scalar} (Left.Lanes (Lane)) and {sign}) /= 0 then Left.Lanes (Lane) else Right.Lanes (Lane))" if name == "Min_Number" else f"(if (Bits_Of_{scalar} (Left.Lanes (Lane)) and {sign}) = 0 then Left.Lanes (Lane) else Right.Lanes (Lane))")
        out += [f"   function {name} (Left, Right : {vector}) return {vector} is", f"      Result : {vector};", "   begin", f"      for Lane in {idx} loop", "         if Left.Lanes (Lane) /= Left.Lanes (Lane) then Result.Lanes (Lane) := Right.Lanes (Lane);", "         elsif Right.Lanes (Lane) /= Right.Lanes (Lane) then Result.Lanes (Lane) := Left.Lanes (Lane);", f"         elsif Left.Lanes (Lane) = 0.0 and then Right.Lanes (Lane) = 0.0 then Result.Lanes (Lane) := {zero_choice};", f"         elsif Left.Lanes (Lane) {choose} Right.Lanes (Lane) then Result.Lanes (Lane) := Left.Lanes (Lane);", "         else Result.Lanes (Lane) := Right.Lanes (Lane); end if;", "      end loop;", "      return Result;", f"   end {name};"]
    out += [f"   function Reduce_Add (Value : {vector}) return {scalar} is", f"      Result : {scalar} := 0.0;", "   begin", f"      for Lane in {idx} loop Result := Result + Value.Lanes (Lane); end loop;", "      return Result;", "   end Reduce_Add;", f"   function Reverse_Lanes (Value : {vector}) return {vector} is", f"      Result : {vector};", "   begin", f"      for Lane in {idx} loop Result.Lanes (Lane) := Value.Lanes ({lanes - 1} - Lane); end loop;", "      return Result;", "   end Reverse_Lanes;"]
    for name, offset in (("Interleave_Low", 0), ("Interleave_High", lanes // 2)):
        out += [f"   function {name} (Left, Right : {vector}) return {vector} is", f"      Result : {vector};", "   begin", f"      for Lane in Natural range 0 .. {lanes // 2 - 1} loop Result.Lanes (2 * Lane) := Left.Lanes (Lane + {offset}); Result.Lanes (2 * Lane + 1) := Right.Lanes (Lane + {offset}); end loop;", "      return Result;", f"   end {name};"]
    out += [f"   function Is_Aligned_16 (Data : {arr}; Start : Natural) return Boolean is (Start in Data'Range and then System.Storage_Elements.To_Integer (Data (Start)'Address) mod 16 = 0);", f"   function Load (Data : {arr}; Start : Natural) return {vector} is (Load_Unaligned (Data, Start));", f"   procedure Store (Data : in out {arr}; Start : Natural; Value : {vector}) is begin Store_Unaligned (Data, Start, Value); end Store;", f"   function Load_Unaligned (Data : {arr}; Start : Natural) return {vector} is", f"      Result : {vector};", "   begin", f"      for Lane in {idx} loop Result.Lanes (Lane) := Data (Start + Lane); end loop;", "      return Result;", "   end Load_Unaligned;", f"   procedure Store_Unaligned (Data : in out {arr}; Start : Natural; Value : {vector}) is begin for Lane in {idx} loop Data (Start + Lane) := Value.Lanes (Lane); end loop; end Store_Unaligned;", f"   function Load_Aligned (Data : {arr}; Start : Natural) return {vector} is (Load_Unaligned (Data, Start));", f"   procedure Store_Aligned (Data : in out {arr}; Start : Natural; Value : {vector}) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;", f"   function Load_Partial (Data : {arr}; Start : Natural; Count : {count}) return {vector} is", f"      Result : {vector} := Zero;", "   begin if Count > 0 then for Lane in Natural range 0 .. Count - 1 loop Result.Lanes (Lane) := Data (Start + Lane); end loop; end if; return Result; end Load_Partial;", f"   procedure Store_Partial (Data : in out {arr}; Start : Natural; Count : {count}; Value : {vector}) is begin if Count > 0 then for Lane in Natural range 0 .. Count - 1 loop Data (Start + Lane) := Value.Lanes (Lane); end loop; end if; end Store_Partial;", ""]
    return out


def emit_body() -> str:
    out = []
    for item in INTEGER_TYPES:
        out += emit_integer_body(*item)
    for item in FLOAT_TYPES:
        out += emit_float_body(*item)
    for bits, lanes, storage in MASKS:
        mask = mask_for(bits, lanes)
        idx = lane_index(bits, lanes)
        count = lane_count(bits, lanes)
        st = f"Interfaces.{storage}"
        full = str((1 << lanes) - 1)
        out += [f"   function Mask_From_Bit_Mask (Bits : {st}) return {mask} is (Bits => Bits and {full});", f"   function To_Bit_Mask (Mask : {mask}) return {st} is (Mask.Bits);", f"   function Test (Mask : {mask}; Lane : {idx}) return Boolean is ((Mask.Bits and Interfaces.Shift_Left ({st}'(1), Lane)) /= 0);", f"   function Any_True (Mask : {mask}) return Boolean is (Mask.Bits /= 0);", f"   function All_True (Mask : {mask}) return Boolean is (Mask.Bits = {full});", f"   function None_True (Mask : {mask}) return Boolean is (Mask.Bits = 0);", f"   function Population_Count (Mask : {mask}) return {count} is", f"      Bits : {st} := Mask.Bits;", f"      Result : {count} := 0;", "   begin while Bits /= 0 loop Result := Result + 1; Bits := Bits and (Bits - 1); end loop; return Result; end Population_Count;", ""]
    return "\n".join(out)


def main() -> None:
    spec = SPEC.read_text()
    spec = replace_block(spec, "GENERATED 128-BIT FAMILIES", emit_spec())
    spec = replace_block(spec, "GENERATED 128-BIT REPRESENTATIONS", emit_private())
    SPEC.write_text(spec)

    body = BODY.read_text()
    body = replace_block(body, "GENERATED 128-BIT SCALAR BODIES", emit_body())
    BODY.write_text(body)


if __name__ == "__main__":
    main()
