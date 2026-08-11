#!/usr/bin/env python3
"""Generate the full 128-bit backend contract and implementations."""

from pathlib import Path

from generate_full_family import (
    FLOAT_TYPES,
    INTEGER_TYPES,
    MASKS,
    ROOT,
    array_name,
    document_spec,
    emit_spec,
    lane_count,
    lane_index,
    lane_values,
    mask_for,
    replace_block,
    strip_generated_docs,
)

SPEC = ROOT / "src" / "flyology_simd-backends-native.ads"
SCALAR_SPEC = ROOT / "src" / "flyology_simd-backends-scalar.ads"
NEON = ROOT / "src" / "backends" / "aarch64" / "flyology_simd-backends-native.adb"
X86 = ROOT / "src" / "backends" / "x86_64" / "flyology_simd-backends-native.adb"
FALLBACKS = [
    ROOT / "src" / "backends" / "scalar" / "flyology_simd-backends-native.adb",
]
TEST = ROOT / "tests" / "family_tests.adb"


def contract() -> str:
    generated = emit_spec()
    return "   function Zero return I8x16;" + generated.split(
        "   function Zero return I8x16;", 1
    )[1]


def call(name: str, result: str, args: str, params: str) -> str:
    return (
        f"   function {name} ({params}) return {result} is\n"
        f"     (Flyology_SIMD.{name} ({args}));"
    )


def fallback_body() -> str:
    out: list[str] = []
    for vector, scalar, bits, lanes, signed in INTEGER_TYPES:
        idx, vals, mask = lane_index(bits, lanes), lane_values(vector), mask_for(bits, lanes)
        arr, count = array_name(scalar), lane_count(bits, lanes)
        out += [
            f"   function Zero return {vector} is (Flyology_SIMD.Zero);",
            call("Splat", vector, "Value", f"Value : {scalar}"),
            call("From_Lanes", vector, "Values", f"Values : {vals}"),
            call("To_Lanes", vals, "Value", f"Value : {vector}"),
            call("Extract", scalar, "Value, Lane", f"Value : {vector}; Lane : {idx}"),
            call("Replace", vector, "Value, Lane, With_Value", f"Value : {vector}; Lane : {idx}; With_Value : {scalar}"),
        ]
        for name in ("Add_Wrap", "Subtract_Wrap", "Multiply_Wrap", "Add_Saturate", "Subtract_Saturate",
                     "Bitwise_And", "Bitwise_Or", "Bitwise_Xor", "Min", "Max",
                     "Interleave_Low", "Interleave_High", "Deinterleave_Even",
                     "Deinterleave_Odd"):
            out.append(call(name, vector, "Left, Right", f"Left, Right : {vector}"))
        out.append(call("Bitwise_Not", vector, "Value", f"Value : {vector}"))
        for name in ("Shift_Left_Logical", "Shift_Right_Logical"):
            out.append(call(name, vector, "Value, Count", f"Value : {vector}; Count : Natural"))
        if signed:
            out.append(call("Shift_Right_Arithmetic", vector, "Value, Count", f"Value : {vector}; Count : Natural"))
        for name in ("Equal", "Less_Than", "Less_Equal", "Greater_Than", "Greater_Equal"):
            out.append(call(name, mask, "Left, Right", f"Left, Right : {vector}"))
        out.append(call("Select_Value", vector, "Mask, If_True, If_False", f"Mask : {mask}; If_True, If_False : {vector}"))
        for name in ("Reduce_Add_Wrap", "Reduce_Min", "Reduce_Max"):
            out.append(call(name, scalar, "Value", f"Value : {vector}"))
        out.append(call("Reverse_Lanes", vector, "Value", f"Value : {vector}"))
        out += [
            call("Is_Aligned_16", "Boolean", "Data, Start", f"Data : {arr}; Start : Natural"),
            call("Load", vector, "Data, Start", f"Data : {arr}; Start : Natural"),
            f"   procedure Store (Data : in out {arr}; Start : Natural; Value : {vector}) is\n   begin Flyology_SIMD.Store (Data, Start, Value); end Store;",
            call("Load_Unaligned", vector, "Data, Start", f"Data : {arr}; Start : Natural"),
            f"   procedure Store_Unaligned (Data : in out {arr}; Start : Natural; Value : {vector}) is\n   begin Flyology_SIMD.Store_Unaligned (Data, Start, Value); end Store_Unaligned;",
            call("Load_Aligned", vector, "Data, Start", f"Data : {arr}; Start : Natural"),
            f"   procedure Store_Aligned (Data : in out {arr}; Start : Natural; Value : {vector}) is\n   begin Flyology_SIMD.Store_Aligned (Data, Start, Value); end Store_Aligned;",
            call("Load_Partial", vector, "Data, Start, Count", f"Data : {arr}; Start : Natural; Count : {count}"),
            f"   procedure Store_Partial (Data : in out {arr}; Start : Natural; Count : {count}; Value : {vector}) is\n   begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;",
        ]
    for vector, scalar, bits, lanes in FLOAT_TYPES:
        idx, vals, mask = lane_index(bits, lanes), lane_values(vector), mask_for(bits, lanes)
        arr, count = array_name(scalar), lane_count(bits, lanes)
        out += [
            f"   function Zero return {vector} is (Flyology_SIMD.Zero);",
            call("Splat", vector, "Value", f"Value : {scalar}"),
            call("From_Lanes", vector, "Values", f"Values : {vals}"),
            call("To_Lanes", vals, "Value", f"Value : {vector}"),
            call("Extract", scalar, "Value, Lane", f"Value : {vector}; Lane : {idx}"),
            call("Replace", vector, "Value, Lane, With_Value", f"Value : {vector}; Lane : {idx}; With_Value : {scalar}"),
        ]
        for name in ("Add", "Subtract", "Multiply", "Divide"):
            out.append(call(name, vector, "Left, Right", f"Left, Right : {vector}"))
        for name in ("Equal", "Less_Than", "Less_Equal", "Greater_Than", "Greater_Equal", "Unordered"):
            out.append(call(name, mask, "Left, Right", f"Left, Right : {vector}"))
        out.append(call("Select_Value", vector, "Mask, If_True, If_False", f"Mask : {mask}; If_True, If_False : {vector}"))
        for name in ("Min_Number", "Max_Number"):
            out.append(call(name, vector, "Left, Right", f"Left, Right : {vector}"))
        out += [
            call("Reduce_Add", scalar, "Value", f"Value : {vector}"),
            call("Reverse_Lanes", vector, "Value", f"Value : {vector}"),
            call("Interleave_Low", vector, "Left, Right", f"Left, Right : {vector}"),
            call("Interleave_High", vector, "Left, Right", f"Left, Right : {vector}"),
            call("Deinterleave_Even", vector, "Left, Right", f"Left, Right : {vector}"),
            call("Deinterleave_Odd", vector, "Left, Right", f"Left, Right : {vector}"),
            call("Is_Aligned_16", "Boolean", "Data, Start", f"Data : {arr}; Start : Natural"),
            call("Load", vector, "Data, Start", f"Data : {arr}; Start : Natural"),
            f"   procedure Store (Data : in out {arr}; Start : Natural; Value : {vector}) is\n   begin Flyology_SIMD.Store (Data, Start, Value); end Store;",
            call("Load_Unaligned", vector, "Data, Start", f"Data : {arr}; Start : Natural"),
            f"   procedure Store_Unaligned (Data : in out {arr}; Start : Natural; Value : {vector}) is\n   begin Flyology_SIMD.Store_Unaligned (Data, Start, Value); end Store_Unaligned;",
            call("Load_Aligned", vector, "Data, Start", f"Data : {arr}; Start : Natural"),
            f"   procedure Store_Aligned (Data : in out {arr}; Start : Natural; Value : {vector}) is\n   begin Flyology_SIMD.Store_Aligned (Data, Start, Value); end Store_Aligned;",
            call("Load_Partial", vector, "Data, Start, Count", f"Data : {arr}; Start : Natural; Count : {count}"),
            f"   procedure Store_Partial (Data : in out {arr}; Start : Natural; Count : {count}; Value : {vector}) is\n   begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;",
        ]
    for bits, lanes, storage in MASKS:
        mask, idx, count = mask_for(bits, lanes), lane_index(bits, lanes), lane_count(bits, lanes)
        st = f"Interfaces.{storage}"
        out += [
            call("Mask_From_Bit_Mask", mask, "Bits", f"Bits : {st}"),
            call("To_Bit_Mask", st, "Mask", f"Mask : {mask}"),
            call("Mask_And", mask, "Left, Right", f"Left, Right : {mask}"),
            call("Mask_Or", mask, "Left, Right", f"Left, Right : {mask}"),
            call("Mask_Xor", mask, "Left, Right", f"Left, Right : {mask}"),
            call("Mask_Not", mask, "Value", f"Value : {mask}"),
            call("Test", "Boolean", "Mask, Lane", f"Mask : {mask}; Lane : {idx}"),
            call("Any_True", "Boolean", "Mask", f"Mask : {mask}"),
            call("All_True", "Boolean", "Mask", f"Mask : {mask}"),
            call("None_True", "Boolean", "Mask", f"Mask : {mask}"),
            call("Population_Count", count, "Mask", f"Mask : {mask}"),
        ]
    return "\n".join(out)


def neon_helpers() -> list[str]:
    return [
        "   generic",
        "      type Vector_Type is private;",
        "      Instruction : String;",
        "   function NEON_Binary_128 (Left, Right : Vector_Type) return Vector_Type;",
        "   function NEON_Binary_128 (Left, Right : Vector_Type) return Vector_Type is",
        "      Result : Vector_Type;",
        "   begin",
        "      Asm (Template => \"ldr q0, [%1]\" & ASCII.LF & ASCII.HT &",
        "           \"ldr q1, [%2]\" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & \"str q0, [%0]\",",
        "           Inputs => [System.Address'Asm_Input (\"r\", Result'Address), System.Address'Asm_Input (\"r\", Left'Address), System.Address'Asm_Input (\"r\", Right'Address)],",
        "           Clobber => \"v0,v1,v2,memory\", Volatile => True);",
        "      return Result;",
        "   end NEON_Binary_128;",
        "",
        "   generic",
        "      type Vector_Type is private;",
        "      Instruction : String;",
        "   function NEON_Unary_128 (Value : Vector_Type) return Vector_Type;",
        "   function NEON_Unary_128 (Value : Vector_Type) return Vector_Type is",
        "      Result : Vector_Type;",
        "   begin",
        "      Asm (Template => \"ldr q0, [%1]\" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & \"str q0, [%0]\",",
        "           Inputs => [System.Address'Asm_Input (\"r\", Result'Address), System.Address'Asm_Input (\"r\", Value'Address)],",
        "           Clobber => \"v0,memory\", Volatile => True);",
        "      return Result;",
        "   end NEON_Unary_128;",
        "",
        "   generic",
        "      type Vector_Type is private;",
        "      Instruction : String;",
        "      Compact : String;",
        "   function NEON_Compare_128 (Left, Right : Vector_Type; Weights : System.Address) return Interfaces.Unsigned_8;",
        "   function NEON_Compare_128 (Left, Right : Vector_Type; Weights : System.Address) return Interfaces.Unsigned_8 is",
        "      Result : Interfaces.Unsigned_32;",
        "   begin",
        "      Asm (Template => \"ldr q0, [%1]\" & ASCII.LF & ASCII.HT & \"ldr q1, [%2]\" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & Compact,",
        "           Outputs => Interfaces.Unsigned_32'Asm_Output (\"=r\", Result),",
        "           Inputs => [System.Address'Asm_Input (\"r\", Left'Address), System.Address'Asm_Input (\"r\", Right'Address), System.Address'Asm_Input (\"r\", Weights)],",
        "           Clobber => \"v0,v1,v2,memory\", Volatile => True);",
        "      return Interfaces.Unsigned_8 (Result and 16#FF#);",
        "   end NEON_Compare_128;",
        "",
        "   generic",
        "      type Vector_Type is private;",
        "      Instruction : String;",
        "   function NEON_Compare_16_Lanes (Left, Right : Vector_Type; Weights : System.Address) return Interfaces.Unsigned_16;",
        "   function NEON_Compare_16_Lanes (Left, Right : Vector_Type; Weights : System.Address) return Interfaces.Unsigned_16 is",
        "      Result : Interfaces.Unsigned_32;",
        "   begin",
        "      Asm (Template => \"ldr q2, [%3]\" & ASCII.LF & ASCII.HT & \"ldr q0, [%1]\" & ASCII.LF & ASCII.HT & \"ldr q1, [%2]\" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & \"and v0.16b, v0.16b, v2.16b\" & ASCII.LF & ASCII.HT & \"ext v1.16b, v0.16b, v0.16b, #8\" & ASCII.LF & ASCII.HT & \"uaddlv h0, v0.8b\" & ASCII.LF & ASCII.HT & \"uaddlv h1, v1.8b\" & ASCII.LF & ASCII.HT & \"umov %w0, v0.h[0]\" & ASCII.LF & ASCII.HT & \"umov w9, v1.h[0]\" & ASCII.LF & ASCII.HT & \"orr %w0, %w0, w9, lsl #8\",",
        "           Outputs => Interfaces.Unsigned_32'Asm_Output (\"=r\", Result), Inputs => [System.Address'Asm_Input (\"r\", Left'Address), System.Address'Asm_Input (\"r\", Right'Address), System.Address'Asm_Input (\"r\", Weights)], Clobber => \"v0,v1,v2,x9,memory\", Volatile => True);",
        "      return Interfaces.Unsigned_16 (Result and 16#FFFF#);",
        "   end NEON_Compare_16_Lanes;",
        "",
        "   generic",
        "      type Vector_Type is private;",
        "      Dup_Instruction : String;",
        "      Shift_Instruction : String;",
        "   function NEON_Shift_128 (Value : Vector_Type; Amount : Interfaces.Integer_64) return Vector_Type;",
        "   function NEON_Shift_128 (Value : Vector_Type; Amount : Interfaces.Integer_64) return Vector_Type is",
        "      Result : Vector_Type;",
        "   begin",
        "      Asm (Template => \"ldr q0, [%1]\" & ASCII.LF & ASCII.HT & Dup_Instruction & ASCII.LF & ASCII.HT & Shift_Instruction & ASCII.LF & ASCII.HT & \"str q0, [%0]\",",
        "           Inputs => [System.Address'Asm_Input (\"r\", Result'Address), System.Address'Asm_Input (\"r\", Value'Address), Interfaces.Integer_64'Asm_Input (\"r\", Amount)],",
        "           Clobber => \"v0,v1,memory\", Volatile => True);",
        "      return Result;",
        "   end NEON_Shift_128;",
        "",
    ]


def compact(bits: int) -> str:
    if bits == 64:
        return (
            '"ushr v0.2d, v0.2d, #63" & ASCII.LF & ASCII.HT & '
            '"umov %w0, v0.s[0]" & ASCII.LF & ASCII.HT & '
            '"umov w9, v0.s[2]" & ASCII.LF & ASCII.HT & '
            '"orr %w0, %w0, w9, lsl #1"'
        )
    shape, lane, move = {
        8: ("16b", "b", "umov %w0, v0.b[0]"),
        16: ("8h", "h", "umov %w0, v0.h[0]"),
        32: ("4s", "s", "umov %w0, v0.s[0]"),
    }[bits]
    reduction = f"addv {lane}0, v0.{shape}"
    return (
        f'"ushr v0.{shape}, v0.{shape}, #{bits - 1}" & ASCII.LF & ASCII.HT & '
        f'"ldr q2, [%3]" & ASCII.LF & ASCII.HT & "mul v0.{shape}, v0.{shape}, v2.{shape}" & ASCII.LF & ASCII.HT & '
        f'"{reduction}" & ASCII.LF & ASCII.HT & "{move}"'
    )


def neon_body() -> str:
    out = neon_helpers()
    for bits, lanes in ((16, 8), (32, 4), (64, 2)):
        scalar = f"U{bits}"
        vals = lane_values(f"{scalar}x{lanes}")
        out += [f"   Weights_{bits}x{lanes} : aliased constant {vals} := [{', '.join(str(1 << n) for n in range(lanes))}];"]
    out.append("")

    for vector, scalar, bits, lanes, signed in INTEGER_TYPES:
        idx, vals, mask = lane_index(bits, lanes), lane_values(vector), mask_for(bits, lanes)
        arr, count = array_name(scalar), lane_count(bits, lanes)
        shape = f"{lanes}{ {8:'b',16:'h',32:'s',64:'d'}[bits]}"
        prefix = "s" if signed else "u"
        weight = "Weights_8x16'Address" if bits == 8 else f"Weights_{bits}x{lanes}'Address"
        compare_type = "Interfaces.Unsigned_16" if bits == 8 else "Interfaces.Unsigned_8"
        # 8-bit comparison already exists; all other operations are emitted here.
        if vector == "I8x16":
            compare = f"Compare_{vector}"
        else:
            out += [
                f"   function Compare_{vector} is new NEON_Compare_128 ({vector}, \"cmeq v0.{shape}, v0.{shape}, v1.{shape}\", {compact(bits)});",
                f"   function Compare_Greater_{vector} is new NEON_Compare_128 ({vector}, \"cm{'gt' if signed else 'hi'} v0.{shape}, v0.{shape}, v1.{shape}\", {compact(bits)});",
                f"   function Compare_Greater_Equal_{vector} is new NEON_Compare_128 ({vector}, \"cm{'ge' if signed else 'hs'} v0.{shape}, v0.{shape}, v1.{shape}\", {compact(bits)});",
            ]
            compare = f"Compare_{vector}"
        inst: dict[str, str] = {
            "Add_Wrap": f"add v0.{shape}, v0.{shape}, v1.{shape}",
            "Subtract_Wrap": f"sub v0.{shape}, v0.{shape}, v1.{shape}",
            "Add_Saturate": f"{prefix}qadd v0.{shape}, v0.{shape}, v1.{shape}",
            "Subtract_Saturate": f"{prefix}qsub v0.{shape}, v0.{shape}, v1.{shape}",
            "Bitwise_And": "and v0.16b, v0.16b, v1.16b",
            "Bitwise_Or": "orr v0.16b, v0.16b, v1.16b",
            "Bitwise_Xor": "eor v0.16b, v0.16b, v1.16b",
            "Min": (f"{prefix}min v0.{shape}, v0.{shape}, v1.{shape}" if bits < 64 else f"cm{'gt' if signed else 'hi'} v2.2d, v0.2d, v1.2d" + ASCII_PLACEHOLDER),
            "Max": (f"{prefix}max v0.{shape}, v0.{shape}, v1.{shape}" if bits < 64 else f"cm{'gt' if signed else 'hi'} v2.2d, v0.2d, v1.2d" + ASCII_PLACEHOLDER),
            "Interleave_Low": f"zip1 v0.{shape}, v0.{shape}, v1.{shape}",
            "Interleave_High": f"zip2 v0.{shape}, v0.{shape}, v1.{shape}",
            "Deinterleave_Even": f"uzp1 v0.{shape}, v0.{shape}, v1.{shape}",
            "Deinterleave_Odd": f"uzp2 v0.{shape}, v0.{shape}, v1.{shape}",
        }
        if bits < 64:
            inst["Multiply_Wrap"] = f"mul v0.{shape}, v0.{shape}, v1.{shape}"
        if bits == 64:
            inst["Min"] = f"cm{'gt' if signed else 'hi'} v2.2d, v0.2d, v1.2d\n      bit v0.16b, v1.16b, v2.16b"
            inst["Max"] = f"cm{'gt' if signed else 'hi'} v2.2d, v0.2d, v1.2d\n      bif v0.16b, v1.16b, v2.16b"
        for name, instruction in inst.items():
            ada_instruction = instruction.replace("\n      ", '" & ASCII.LF & ASCII.HT & "')
            out += [
                f"   function Native_{name}_{vector} is new NEON_Binary_128 ({vector}, \"{ada_instruction}\");",
                f"   function {name} (Left, Right : {vector}) return {vector} is (Native_{name}_{vector} (Left, Right));",
            ]
        out += [
            f"   function Native_Not_{vector} is new NEON_Unary_128 ({vector}, \"mvn v0.16b, v0.16b\");",
            f"   function Bitwise_Not (Value : {vector}) return {vector} is (Native_Not_{vector} (Value));",
        ]
        reverse_instruction = (
            "rev64 v0.16b, v0.16b\" & ASCII.LF & ASCII.HT & \"ext v0.16b, v0.16b, v0.16b, #8"
            if bits == 8 else
            (f"rev64 v0.{shape}, v0.{shape}\" & ASCII.LF & ASCII.HT & \"ext v0.16b, v0.16b, v0.16b, #8" if bits < 64 else "ext v0.16b, v0.16b, v0.16b, #8")
        )
        out += [
            f"   function Native_Reverse_{vector} is new NEON_Unary_128 ({vector}, \"{reverse_instruction}\");",
            f"   function Reverse_Lanes (Value : {vector}) return {vector} is (Native_Reverse_{vector} (Value));",
            f"   function Zero return {vector} is (Flyology_SIMD.Zero);",
            call("Splat", vector, "Value", f"Value : {scalar}"),
            call("From_Lanes", vector, "Values", f"Values : {vals}"),
            call("To_Lanes", vals, "Value", f"Value : {vector}"),
            call("Extract", scalar, "Value, Lane", f"Value : {vector}; Lane : {idx}"),
            call("Replace", vector, "Value, Lane, With_Value", f"Value : {vector}; Lane : {idx}; With_Value : {scalar}"),
        ]
        if bits == 64:
            out.append(call("Multiply_Wrap", vector, "Left, Right", f"Left, Right : {vector}"))
        dup = f"dup v1.{shape}, %{'2' if bits == 64 else 'w2'}"
        for name, amount, instruction in (
            ("Shift_Left_Logical", "Interfaces.Integer_64 (Count)", f"ushl v0.{shape}, v0.{shape}, v1.{shape}"),
            ("Shift_Right_Logical", "-Interfaces.Integer_64 (Count)", f"ushl v0.{shape}, v0.{shape}, v1.{shape}"),
        ):
            out += [
                f"   function Native_{name}_{vector} is new NEON_Shift_128 ({vector}, \"{dup}\", \"{instruction}\");",
                f"   function {name} (Value : {vector}; Count : Natural) return {vector} is",
                f"     (if Count >= {bits} then Flyology_SIMD.Zero else Native_{name}_{vector} (Value, {amount}));",
            ]
        if signed:
            out += [
                f"   function Native_SRA_{vector} is new NEON_Shift_128 ({vector}, \"{dup}\", \"sshl v0.{shape}, v0.{shape}, v1.{shape}\");",
                f"   function Shift_Right_Arithmetic (Value : {vector}; Count : Natural) return {vector} is",
                f"     (if Count >= {bits} then Flyology_SIMD.Shift_Right_Arithmetic (Value, Count) else Native_SRA_{vector} (Value, -Interfaces.Integer_64 (Count)));",
            ]
        if vector == "I8x16":
            # Signed byte comparison needs its own compacting instantiations.
            out += [
                f"   function Compare_{vector} is new NEON_Compare_16_Lanes ({vector}, \"cmeq v0.16b, v0.16b, v1.16b\");",
                f"   function Compare_Greater_{vector} is new NEON_Compare_16_Lanes ({vector}, \"cmgt v0.16b, v0.16b, v1.16b\");",
                f"   function Compare_Greater_Equal_{vector} is new NEON_Compare_16_Lanes ({vector}, \"cmge v0.16b, v0.16b, v1.16b\");",
            ]
        out += [
            f"   function Equal (Left, Right : {vector}) return {mask} is (Mask_From_Bit_Mask ({compare} (Left, Right, {weight})));",
            f"   function Greater_Than (Left, Right : {vector}) return {mask} is (Mask_From_Bit_Mask (Compare_Greater_{vector} (Left, Right, {weight})));",
            f"   function Greater_Equal (Left, Right : {vector}) return {mask} is (Mask_From_Bit_Mask (Compare_Greater_Equal_{vector} (Left, Right, {weight})));",
            f"   function Less_Than (Left, Right : {vector}) return {mask} is (Greater_Than (Left => Right, Right => Left));",
            f"   function Less_Equal (Left, Right : {vector}) return {mask} is (Greater_Equal (Left => Right, Right => Left));",
            call("Select_Value", vector, "Mask, If_True, If_False", f"Mask : {mask}; If_True, If_False : {vector}"),
            call("Reduce_Add_Wrap", scalar, "Value", f"Value : {vector}"),
            call("Reduce_Min", scalar, "Value", f"Value : {vector}"),
            call("Reduce_Max", scalar, "Value", f"Value : {vector}"),
        ]
        out += memory_body(vector, arr, count)

    for vector, scalar, bits, lanes in FLOAT_TYPES:
        idx, vals, mask = lane_index(bits, lanes), lane_values(vector), mask_for(bits, lanes)
        arr, count = array_name(scalar), lane_count(bits, lanes)
        shape = f"{lanes}{'s' if bits == 32 else 'd'}"
        weight = f"Weights_{bits}x{lanes}'Address"
        for name, op in (("Add", "fadd"), ("Subtract", "fsub"), ("Multiply", "fmul"), ("Divide", "fdiv"), ("Min_Number", "fminnm"), ("Max_Number", "fmaxnm"), ("Interleave_Low", "zip1"), ("Interleave_High", "zip2"), ("Deinterleave_Even", "uzp1"), ("Deinterleave_Odd", "uzp2")):
            instruction = f"{op} v0.{shape}, v0.{shape}, v1.{shape}"
            out += [f"   function Native_{name}_{vector} is new NEON_Binary_128 ({vector}, \"{instruction}\");", f"   function {name} (Left, Right : {vector}) return {vector} is (Native_{name}_{vector} (Left, Right));"]
        reverse = ("rev64 v0.4s, v0.4s\" & ASCII.LF & ASCII.HT & \"ext v0.16b, v0.16b, v0.16b, #8" if bits == 32 else "ext v0.16b, v0.16b, v0.16b, #8")
        out += [f"   function Native_Reverse_{vector} is new NEON_Unary_128 ({vector}, \"{reverse}\");", f"   function Reverse_Lanes (Value : {vector}) return {vector} is (Native_Reverse_{vector} (Value));"]
        for name, instruction in (("Equal", "fcmeq"), ("Greater_Than", "fcmgt"), ("Greater_Equal", "fcmge")):
            out += [f"   function Compare_{name}_{vector} is new NEON_Compare_128 ({vector}, \"{instruction} v0.{shape}, v0.{shape}, v1.{shape}\", {compact(bits)});", f"   function {name} (Left, Right : {vector}) return {mask} is (Mask_From_Bit_Mask (Compare_{name}_{vector} (Left, Right, {weight})));"]
        out += [
            call("Unordered", mask, "Left, Right", f"Left, Right : {vector}"),
            f"   function Less_Than (Left, Right : {vector}) return {mask} is (Greater_Than (Left => Right, Right => Left));",
            f"   function Less_Equal (Left, Right : {vector}) return {mask} is (Greater_Equal (Left => Right, Right => Left));",
            f"   function Zero return {vector} is (Flyology_SIMD.Zero);",
            call("Splat", vector, "Value", f"Value : {scalar}"), call("From_Lanes", vector, "Values", f"Values : {vals}"),
            call("To_Lanes", vals, "Value", f"Value : {vector}"), call("Extract", scalar, "Value, Lane", f"Value : {vector}; Lane : {idx}"),
            call("Replace", vector, "Value, Lane, With_Value", f"Value : {vector}; Lane : {idx}; With_Value : {scalar}"),
            call("Select_Value", vector, "Mask, If_True, If_False", f"Mask : {mask}; If_True, If_False : {vector}"),
            call("Reduce_Add", scalar, "Value", f"Value : {vector}"),
        ]
        out += memory_body(vector, arr, count)

    for bits, lanes, storage in MASKS:
        mask, idx, count = mask_for(bits, lanes), lane_index(bits, lanes), lane_count(bits, lanes)
        st = f"Interfaces.{storage}"
        out += [call("Mask_From_Bit_Mask", mask, "Bits", f"Bits : {st}"), call("To_Bit_Mask", st, "Mask", f"Mask : {mask}"), call("Mask_And", mask, "Left, Right", f"Left, Right : {mask}"), call("Mask_Or", mask, "Left, Right", f"Left, Right : {mask}"), call("Mask_Xor", mask, "Left, Right", f"Left, Right : {mask}"), call("Mask_Not", mask, "Value", f"Value : {mask}"), call("Test", "Boolean", "Mask, Lane", f"Mask : {mask}; Lane : {idx}"), call("Any_True", "Boolean", "Mask", f"Mask : {mask}"), call("All_True", "Boolean", "Mask", f"Mask : {mask}"), call("None_True", "Boolean", "Mask", f"Mask : {mask}"), call("Population_Count", count, "Mask", f"Mask : {mask}")]
    return "\n".join(out)


ASCII_PLACEHOLDER = ""  # used only while constructing multi-instruction strings


def memory_body(vector: str, arr: str, count: str) -> list[str]:
    return [
        call("Is_Aligned_16", "Boolean", "Data, Start", f"Data : {arr}; Start : Natural"),
        f"   function Load (Data : {arr}; Start : Natural) return {vector} is (Load_Unaligned (Data, Start));",
        f"   procedure Store (Data : in out {arr}; Start : Natural; Value : {vector}) is begin Store_Unaligned (Data, Start, Value); end Store;",
        f"   function Load_Unaligned (Data : {arr}; Start : Natural) return {vector} is",
        f"      Result : {vector};",
        "   begin",
        "      Asm (Template => \"ldr q0, [%1]\" & ASCII.LF & ASCII.HT & \"str q0, [%0]\", Inputs => [System.Address'Asm_Input (\"r\", Result'Address), System.Address'Asm_Input (\"r\", Data (Start)'Address)], Clobber => \"v0,memory\", Volatile => True);",
        "      return Result;",
        "   end Load_Unaligned;",
        f"   procedure Store_Unaligned (Data : in out {arr}; Start : Natural; Value : {vector}) is",
        "   begin",
        "      Asm (Template => \"ldr q0, [%1]\" & ASCII.LF & ASCII.HT & \"str q0, [%0]\", Inputs => [System.Address'Asm_Input (\"r\", Data (Start)'Address), System.Address'Asm_Input (\"r\", Value'Address)], Clobber => \"v0,memory\", Volatile => True);",
        "   end Store_Unaligned;",
        f"   function Load_Aligned (Data : {arr}; Start : Natural) return {vector} is (Load_Unaligned (Data, Start));",
        f"   procedure Store_Aligned (Data : in out {arr}; Start : Natural; Value : {vector}) is begin Store_Unaligned (Data, Start, Value); end Store_Aligned;",
        call("Load_Partial", vector, "Data, Start, Count", f"Data : {arr}; Start : Natural; Count : {count}"),
        f"   procedure Store_Partial (Data : in out {arr}; Start : Natural; Count : {count}; Value : {vector}) is begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;",
    ]


def x86_helpers() -> list[str]:
    """SSE2-only leaves shared by the generated 128-bit x86 family."""
    return [
        "   Sign_8 : aliased constant Lane_Values_8x16 := [others => 16#80#];",
        "   Sign_16 : aliased constant Lane_Values_8x16 := [for Lane in Lane_Index_8x16 => (if Lane mod 2 = 1 then 16#80# else 0)];",
        "   Sign_32 : aliased constant Lane_Values_8x16 := [for Lane in Lane_Index_8x16 => (if Lane mod 4 = 3 then 16#80# else 0)];",
        "   Weights_X86_8 : aliased constant Lane_Values_8x16 := [1, 2, 4, 8, 16, 32, 64, 128, 1, 2, 4, 8, 16, 32, 64, 128];",
        "   Weights_X86_16 : aliased constant Lane_Values_U16x8 := [1, 2, 4, 8, 16, 32, 64, 128];",
        "   Weights_X86_32 : aliased constant Lane_Values_U32x4 := [1, 2, 4, 8];",
        "   Weights_X86_64 : aliased constant Lane_Values_U64x2 := [1, 2];",
        "",
        "   generic",
        "      type Vector_Type is private;",
        "      Instruction : String;",
        "   function SSE2_Binary_128 (Left, Right : Vector_Type) return Vector_Type;",
        "   function SSE2_Binary_128 (Left, Right : Vector_Type) return Vector_Type is",
        "      Result : Vector_Type;",
        "   begin",
        "      Asm (Template => \"movdqu (%1), %%xmm0\" & ASCII.LF & ASCII.HT & \"movdqu (%2), %%xmm1\" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & \"movdqu %%xmm0, (%0)\", Inputs => [System.Address'Asm_Input (\"r\", Result'Address), System.Address'Asm_Input (\"r\", Left'Address), System.Address'Asm_Input (\"r\", Right'Address)], Clobber => \"xmm0,xmm1,xmm2,xmm3,xmm4,xmm5,xmm6,xmm7,memory\", Volatile => True);",
        "      return Result;",
        "   end SSE2_Binary_128;",
        "",
        "   generic",
        "      type Vector_Type is private;",
        "      Instruction : String;",
        "   function SSE2_Unary_128 (Value : Vector_Type) return Vector_Type;",
        "   function SSE2_Unary_128 (Value : Vector_Type) return Vector_Type is",
        "      Result : Vector_Type;",
        "   begin",
        "      Asm (Template => \"movdqu (%1), %%xmm0\" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & \"movdqu %%xmm0, (%0)\", Inputs => [System.Address'Asm_Input (\"r\", Result'Address), System.Address'Asm_Input (\"r\", Value'Address)], Clobber => \"xmm0,xmm1,xmm2,memory\", Volatile => True);",
        "      return Result;",
        "   end SSE2_Unary_128;",
        "",
        "   generic",
        "      type Vector_Type is private;",
        "      Lane_Bits : Positive;",
        "      Instruction : String;",
        "   function SSE2_Compare_128 (Left, Right : Vector_Type; Sign : System.Address) return Interfaces.Unsigned_16;",
        "   function SSE2_Compare_128 (Left, Right : Vector_Type; Sign : System.Address) return Interfaces.Unsigned_16 is",
        "      Raw, Packed : Interfaces.Unsigned_32;",
        "   begin",
        "      Asm (Template => \"movdqu (%1), %%xmm0\" & ASCII.LF & ASCII.HT & \"movdqu (%2), %%xmm1\" & ASCII.LF & ASCII.HT & \"movdqu (%3), %%xmm7\" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & \"pmovmskb %%xmm0, %0\", Outputs => Interfaces.Unsigned_32'Asm_Output (\"=r\", Raw), Inputs => [System.Address'Asm_Input (\"r\", Left'Address), System.Address'Asm_Input (\"r\", Right'Address), System.Address'Asm_Input (\"r\", Sign)], Clobber => \"xmm0,xmm1,xmm2,xmm3,xmm4,xmm5,xmm6,xmm7,memory\", Volatile => True);",
        "      case Lane_Bits is",
        "         when 8 => Packed := Raw and 16#FFFF#;",
        "         when 16 => Packed := Interfaces.Shift_Right (Raw, 1) and 16#5555#; Packed := (Packed or Interfaces.Shift_Right (Packed, 1)) and 16#3333#; Packed := (Packed or Interfaces.Shift_Right (Packed, 2)) and 16#0F0F#; Packed := (Packed or Interfaces.Shift_Right (Packed, 4)) and 16#00FF#;",
        "         when 32 => Packed := Interfaces.Shift_Right (Raw, 3) and 16#1111#; Packed := (Packed or Interfaces.Shift_Right (Packed, 3)) and 16#0303#; Packed := (Packed or Interfaces.Shift_Right (Packed, 6)) and 16#000F#;",
        "         when others => Packed := Interfaces.Shift_Right (Raw, 7) and 16#0101#; Packed := (Packed or Interfaces.Shift_Right (Packed, 7)) and 3;",
        "      end case;",
        "      return Interfaces.Unsigned_16 (Packed);",
        "   end SSE2_Compare_128;",
        "",
        "   generic",
        "      type Vector_Type is private;",
        "      Instruction : String;",
        "   function SSE2_Shift_128 (Value : Vector_Type; Count : Interfaces.Unsigned_32) return Vector_Type;",
        "   function SSE2_Shift_128 (Value : Vector_Type; Count : Interfaces.Unsigned_32) return Vector_Type is",
        "      Result : Vector_Type; Local_Count : aliased Interfaces.Unsigned_32 := Count;",
        "   begin",
        "      Asm (Template => \"movdqu (%1), %%xmm0\" & ASCII.LF & ASCII.HT & \"movd (%2), %%xmm1\" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & \"movdqu %%xmm0, (%0)\", Inputs => [System.Address'Asm_Input (\"r\", Result'Address), System.Address'Asm_Input (\"r\", Value'Address), System.Address'Asm_Input (\"r\", Local_Count'Address)], Clobber => \"xmm0,xmm1,xmm2,memory\", Volatile => True);",
        "      return Result;",
        "   end SSE2_Shift_128;",
        "",
        "   generic",
        "      type Vector_Type is private;",
        "      Lane_Bits : Positive;",
        "   function SSE2_Select_128 (Bits : Interfaces.Unsigned_16; Weights : System.Address; If_True, If_False : Vector_Type) return Vector_Type;",
        "   function SSE2_Select_128 (Bits : Interfaces.Unsigned_16; Weights : System.Address; If_True, If_False : Vector_Type) return Vector_Type is",
        "      Result : Vector_Type; Local_Bits : aliased Interfaces.Unsigned_32 := Interfaces.Unsigned_32 (Bits);",
        "      Expand : constant String := (case Lane_Bits is when 8 => \"punpcklbw %%xmm2, %%xmm2\" & ASCII.LF & ASCII.HT & \"punpcklwd %%xmm2, %%xmm2\" & ASCII.LF & ASCII.HT & \"punpckldq %%xmm2, %%xmm2\", when 16 => \"pshuflw $0, %%xmm2, %%xmm2\" & ASCII.LF & ASCII.HT & \"pshufd $0, %%xmm2, %%xmm2\", when 32 => \"pshufd $0, %%xmm2, %%xmm2\", when others => \"punpcklqdq %%xmm2, %%xmm2\");",
        "      Compare : constant String := (if Lane_Bits = 8 then \"pcmpeqb\" elsif Lane_Bits = 16 then \"pcmpeqw\" else \"pcmpeqd\");",
        "      Replicate_64 : constant String := (if Lane_Bits = 64 then \"pshufd $0xA0, %%xmm2, %%xmm2\" & ASCII.LF & ASCII.HT else \"\");",
        "   begin",
        "      Asm (Template => \"movd (%1), %%xmm2\" & ASCII.LF & ASCII.HT & Expand & ASCII.LF & ASCII.HT & \"pand (%2), %%xmm2\" & ASCII.LF & ASCII.HT & \"pxor %%xmm3, %%xmm3\" & ASCII.LF & ASCII.HT & Compare & \" %%xmm3, %%xmm2\" & ASCII.LF & ASCII.HT & Replicate_64 & \"pcmpeqd %%xmm3, %%xmm3\" & ASCII.LF & ASCII.HT & \"pxor %%xmm3, %%xmm2\" & ASCII.LF & ASCII.HT & \"movdqu %%xmm2, %%xmm3\" & ASCII.LF & ASCII.HT & \"pand (%3), %%xmm3\" & ASCII.LF & ASCII.HT & \"pandn (%4), %%xmm2\" & ASCII.LF & ASCII.HT & \"por %%xmm3, %%xmm2\" & ASCII.LF & ASCII.HT & \"movdqu %%xmm2, (%0)\", Inputs => [System.Address'Asm_Input (\"r\", Result'Address), System.Address'Asm_Input (\"r\", Local_Bits'Address), System.Address'Asm_Input (\"r\", Weights), System.Address'Asm_Input (\"r\", If_True'Address), System.Address'Asm_Input (\"r\", If_False'Address)], Clobber => \"xmm2,xmm3,memory\", Volatile => True);",
        "      return Result;",
        "   end SSE2_Select_128;",
        "",
    ]


def x86_memory_body(vector: str, arr: str, count: str) -> list[str]:
    return [
        call("Is_Aligned_16", "Boolean", "Data, Start", f"Data : {arr}; Start : Natural"),
        f"   function Load (Data : {arr}; Start : Natural) return {vector} is (Load_Unaligned (Data, Start));",
        f"   procedure Store (Data : in out {arr}; Start : Natural; Value : {vector}) is begin Store_Unaligned (Data, Start, Value); end Store;",
        f"   function Load_Unaligned (Data : {arr}; Start : Natural) return {vector} is",
        f"      Result : {vector};",
        "   begin Asm (Template => \"movdqu (%1), %%xmm0\" & ASCII.LF & ASCII.HT & \"movdqu %%xmm0, (%0)\", Inputs => [System.Address'Asm_Input (\"r\", Result'Address), System.Address'Asm_Input (\"r\", Data (Start)'Address)], Clobber => \"xmm0,memory\", Volatile => True); return Result; end Load_Unaligned;",
        f"   procedure Store_Unaligned (Data : in out {arr}; Start : Natural; Value : {vector}) is",
        "   begin Asm (Template => \"movdqu (%1), %%xmm0\" & ASCII.LF & ASCII.HT & \"movdqu %%xmm0, (%0)\", Inputs => [System.Address'Asm_Input (\"r\", Data (Start)'Address), System.Address'Asm_Input (\"r\", Value'Address)], Clobber => \"xmm0,memory\", Volatile => True); end Store_Unaligned;",
        f"   function Load_Aligned (Data : {arr}; Start : Natural) return {vector} is",
        f"      Result : {vector};",
        "   begin Asm (Template => \"movdqa (%1), %%xmm0\" & ASCII.LF & ASCII.HT & \"movdqu %%xmm0, (%0)\", Inputs => [System.Address'Asm_Input (\"r\", Result'Address), System.Address'Asm_Input (\"r\", Data (Start)'Address)], Clobber => \"xmm0,memory\", Volatile => True); return Result; end Load_Aligned;",
        f"   procedure Store_Aligned (Data : in out {arr}; Start : Natural; Value : {vector}) is",
        "   begin Asm (Template => \"movdqu (%1), %%xmm0\" & ASCII.LF & ASCII.HT & \"movdqa %%xmm0, (%0)\", Inputs => [System.Address'Asm_Input (\"r\", Data (Start)'Address), System.Address'Asm_Input (\"r\", Value'Address)], Clobber => \"xmm0,memory\", Volatile => True); end Store_Aligned;",
        call("Load_Partial", vector, "Data, Start, Count", f"Data : {arr}; Start : Natural; Count : {count}"),
        f"   procedure Store_Partial (Data : in out {arr}; Start : Natural; Count : {count}; Value : {vector}) is begin Flyology_SIMD.Store_Partial (Data, Start, Count, Value); end Store_Partial;",
    ]


def x86_ada_instruction(instruction: str) -> str:
    return instruction.replace("\n", '" & ASCII.LF & ASCII.HT & "')


def x86_body() -> str:
    out = x86_helpers()
    multiplication = {
        8: (
            "movdqu %%xmm0, %%xmm2\nmovdqu %%xmm1, %%xmm4\nmovdqu %%xmm1, %%xmm5\n"
            "pxor %%xmm3, %%xmm3\npunpcklbw %%xmm3, %%xmm0\npunpckhbw %%xmm3, %%xmm2\n"
            "punpcklbw %%xmm3, %%xmm4\npunpckhbw %%xmm3, %%xmm5\npmullw %%xmm4, %%xmm0\n"
            "pmullw %%xmm5, %%xmm2\npcmpeqd %%xmm6, %%xmm6\npsrlw $8, %%xmm6\n"
            "pand %%xmm6, %%xmm0\npand %%xmm6, %%xmm2\npackuswb %%xmm2, %%xmm0"
        ),
        16: "pmullw %%xmm1, %%xmm0",
        32: (
            "movdqu %%xmm0, %%xmm2\nmovdqu %%xmm1, %%xmm3\npsrldq $4, %%xmm2\n"
            "psrldq $4, %%xmm3\npmuludq %%xmm1, %%xmm0\npmuludq %%xmm3, %%xmm2\n"
            "pshufd $0x88, %%xmm0, %%xmm0\npshufd $0x88, %%xmm2, %%xmm2\n"
            "punpckldq %%xmm2, %%xmm0"
        ),
        64: (
            "movdqu %%xmm0, %%xmm2\npshufd $0xB1, %%xmm2, %%xmm2\npmuludq %%xmm1, %%xmm2\n"
            "movdqu %%xmm1, %%xmm3\npshufd $0xB1, %%xmm3, %%xmm3\nmovdqu %%xmm0, %%xmm4\n"
            "pmuludq %%xmm3, %%xmm4\npaddq %%xmm4, %%xmm2\npsllq $32, %%xmm2\n"
            "pmuludq %%xmm1, %%xmm0\npaddq %%xmm2, %%xmm0"
        ),
    }
    reverse = {
        8: "movdqu %%xmm0, %%xmm1\npsrlw $8, %%xmm0\npsllw $8, %%xmm1\npor %%xmm1, %%xmm0\npshuflw $0x1B, %%xmm0, %%xmm0\npshufhw $0x1B, %%xmm0, %%xmm0\npshufd $0x4E, %%xmm0, %%xmm0",
        16: "pshuflw $0x1B, %%xmm0, %%xmm0\npshufhw $0x1B, %%xmm0, %%xmm0\npshufd $0x4E, %%xmm0, %%xmm0",
        32: "pshufd $0x1B, %%xmm0, %%xmm0",
        64: "pshufd $0x4E, %%xmm0, %%xmm0",
    }
    interleave = {
        8: ("punpcklbw", "punpckhbw"),
        16: ("punpcklwd", "punpckhwd"),
        32: ("punpckldq", "punpckhdq"),
        64: ("punpcklqdq", "punpckhqdq"),
    }
    deinterleave = {
        8: (
            "pcmpeqd %%xmm2, %%xmm2\npsrlw $8, %%xmm2\npand %%xmm2, %%xmm0\npand %%xmm2, %%xmm1\npackuswb %%xmm1, %%xmm0",
            "psrlw $8, %%xmm0\npsrlw $8, %%xmm1\npackuswb %%xmm1, %%xmm0",
        ),
        16: (
            "pshuflw $0x88, %%xmm0, %%xmm0\npshufhw $0x88, %%xmm0, %%xmm0\npshufd $0x88, %%xmm0, %%xmm0\npshuflw $0x88, %%xmm1, %%xmm1\npshufhw $0x88, %%xmm1, %%xmm1\npshufd $0x88, %%xmm1, %%xmm1\npunpcklqdq %%xmm1, %%xmm0",
            "pshuflw $0xDD, %%xmm0, %%xmm0\npshufhw $0xDD, %%xmm0, %%xmm0\npshufd $0x88, %%xmm0, %%xmm0\npshuflw $0xDD, %%xmm1, %%xmm1\npshufhw $0xDD, %%xmm1, %%xmm1\npshufd $0x88, %%xmm1, %%xmm1\npunpcklqdq %%xmm1, %%xmm0",
        ),
        32: (
            "pshufd $0x88, %%xmm0, %%xmm0\npshufd $0x88, %%xmm1, %%xmm1\npunpcklqdq %%xmm1, %%xmm0",
            "pshufd $0xDD, %%xmm0, %%xmm0\npshufd $0xDD, %%xmm1, %%xmm1\npunpcklqdq %%xmm1, %%xmm0",
        ),
        64: ("punpcklqdq %%xmm1, %%xmm0", "punpckhqdq %%xmm1, %%xmm0"),
    }
    shift_left = {
        8: "movdqu %%xmm0, %%xmm2\npxor %%xmm3, %%xmm3\npunpcklbw %%xmm3, %%xmm0\npunpckhbw %%xmm3, %%xmm2\npsllw %%xmm1, %%xmm0\npsllw %%xmm1, %%xmm2\npcmpeqd %%xmm3, %%xmm3\npsrlw $8, %%xmm3\npand %%xmm3, %%xmm0\npand %%xmm3, %%xmm2\npackuswb %%xmm2, %%xmm0",
        16: "psllw %%xmm1, %%xmm0",
        32: "pslld %%xmm1, %%xmm0",
        64: "psllq %%xmm1, %%xmm0",
    }
    shift_right = {
        8: "movdqu %%xmm0, %%xmm2\npxor %%xmm3, %%xmm3\npunpcklbw %%xmm3, %%xmm0\npunpckhbw %%xmm3, %%xmm2\npsrlw %%xmm1, %%xmm0\npsrlw %%xmm1, %%xmm2\npackuswb %%xmm2, %%xmm0",
        16: "psrlw %%xmm1, %%xmm0",
        32: "psrld %%xmm1, %%xmm0",
        64: "psrlq %%xmm1, %%xmm0",
    }
    shift_arithmetic = {
        8: "movdqu %%xmm0, %%xmm2\npxor %%xmm3, %%xmm3\npunpcklbw %%xmm3, %%xmm0\npunpckhbw %%xmm3, %%xmm2\npsllw $8, %%xmm0\npsllw $8, %%xmm2\npsraw $8, %%xmm0\npsraw $8, %%xmm2\npsraw %%xmm1, %%xmm0\npsraw %%xmm1, %%xmm2\npacksswb %%xmm2, %%xmm0",
        16: "psraw %%xmm1, %%xmm0",
        32: "psrad %%xmm1, %%xmm0",
    }
    eq_instruction = {
        8: "pcmpeqb %%xmm1, %%xmm0",
        16: "pcmpeqw %%xmm1, %%xmm0",
        32: "pcmpeqd %%xmm1, %%xmm0",
        64: "pcmpeqd %%xmm1, %%xmm0\npshufd $0xB1, %%xmm0, %%xmm2\npand %%xmm2, %%xmm0\npshufd $0xA0, %%xmm0, %%xmm0",
    }
    signed_gt = {
        8: "pcmpgtb %%xmm1, %%xmm0",
        16: "pcmpgtw %%xmm1, %%xmm0",
        32: "pcmpgtd %%xmm1, %%xmm0",
        64: (
            "movdqu %%xmm0, %%xmm2\npcmpgtd %%xmm1, %%xmm2\npshufd $0xF5, %%xmm2, %%xmm2\n"
            "movdqu %%xmm0, %%xmm3\npcmpeqd %%xmm1, %%xmm3\npshufd $0xF5, %%xmm3, %%xmm3\n"
            "movdqu %%xmm0, %%xmm4\nmovdqu %%xmm1, %%xmm5\npxor %%xmm7, %%xmm4\npxor %%xmm7, %%xmm5\n"
            "pcmpgtd %%xmm5, %%xmm4\npshufd $0xA0, %%xmm4, %%xmm4\npand %%xmm3, %%xmm4\npor %%xmm4, %%xmm2\nmovdqu %%xmm2, %%xmm0"
        ),
    }
    unsigned_gt = {
        bits: (
            f"pxor %%xmm7, %%xmm0\npxor %%xmm7, %%xmm1\n{ {8:'pcmpgtb',16:'pcmpgtw',32:'pcmpgtd'}[bits] } %%xmm1, %%xmm0"
        ) for bits in (8, 16, 32)
    }
    unsigned_gt[64] = (
        "movdqu %%xmm0, %%xmm2\nmovdqu %%xmm1, %%xmm3\npxor %%xmm7, %%xmm2\npxor %%xmm7, %%xmm3\n"
        "pcmpgtd %%xmm3, %%xmm2\npshufd $0xF5, %%xmm2, %%xmm2\nmovdqu %%xmm0, %%xmm3\n"
        "pcmpeqd %%xmm1, %%xmm3\npshufd $0xF5, %%xmm3, %%xmm3\npxor %%xmm7, %%xmm0\n"
        "pxor %%xmm7, %%xmm1\npcmpgtd %%xmm1, %%xmm0\npshufd $0xA0, %%xmm0, %%xmm0\n"
        "pand %%xmm3, %%xmm0\npor %%xmm2, %%xmm0"
    )

    for vector, scalar, bits, lanes, signed in INTEGER_TYPES:
        if vector == "U8x16":
            continue
        idx, vals, mask = lane_index(bits, lanes), lane_values(vector), mask_for(bits, lanes)
        arr, count = array_name(scalar), lane_count(bits, lanes)
        sign = "Sign_8'Address" if bits == 8 else ("Sign_16'Address" if bits == 16 else "Sign_32'Address")
        weights = f"Weights_X86_{bits}'Address"
        storage_cast = "" if lanes == 16 else "Interfaces.Unsigned_8"
        bit = lambda expression: expression if not storage_cast else f"{storage_cast} ({expression})"
        instructions = {
            "Add_Wrap": f"padd{ {8:'b',16:'w',32:'d',64:'q'}[bits] } %%xmm1, %%xmm0",
            "Subtract_Wrap": f"psub{ {8:'b',16:'w',32:'d',64:'q'}[bits] } %%xmm1, %%xmm0",
            "Multiply_Wrap": multiplication[bits],
            "Bitwise_And": "pand %%xmm1, %%xmm0",
            "Bitwise_Or": "por %%xmm1, %%xmm0",
            "Bitwise_Xor": "pxor %%xmm1, %%xmm0",
            "Interleave_Low": f"{interleave[bits][0]} %%xmm1, %%xmm0",
            "Interleave_High": f"{interleave[bits][1]} %%xmm1, %%xmm0",
            "Deinterleave_Even": deinterleave[bits][0],
            "Deinterleave_Odd": deinterleave[bits][1],
        }
        if bits <= 16:
            prefix = "s" if signed else "us"
            instructions["Add_Saturate"] = f"padd{prefix}{'b' if bits == 8 else 'w'} %%xmm1, %%xmm0"
            instructions["Subtract_Saturate"] = f"psub{prefix}{'b' if bits == 8 else 'w'} %%xmm1, %%xmm0"
        if (not signed and bits == 8) or (signed and bits == 16):
            instructions["Min"] = f"pmin{'ub' if bits == 8 else 'sw'} %%xmm1, %%xmm0"
            instructions["Max"] = f"pmax{'ub' if bits == 8 else 'sw'} %%xmm1, %%xmm0"
        for name, instruction in instructions.items():
            out += [
                f"   function Native_{name}_{vector} is new SSE2_Binary_128 ({vector}, \"{x86_ada_instruction(instruction)}\");",
                f"   function {name} (Left, Right : {vector}) return {vector} is (Native_{name}_{vector} (Left, Right));",
            ]
        out += [
            f"   function Native_Not_{vector} is new SSE2_Unary_128 ({vector}, \"pcmpeqd %%xmm1, %%xmm1\" & ASCII.LF & ASCII.HT & \"pxor %%xmm1, %%xmm0\");",
            f"   function Bitwise_Not (Value : {vector}) return {vector} is (Native_Not_{vector} (Value));",
            f"   function Native_Reverse_{vector} is new SSE2_Unary_128 ({vector}, \"{x86_ada_instruction(reverse[bits])}\");",
            f"   function Reverse_Lanes (Value : {vector}) return {vector} is (Native_Reverse_{vector} (Value));",
            f"   function Compare_Equal_{vector} is new SSE2_Compare_128 ({vector}, {bits}, \"{x86_ada_instruction(eq_instruction[bits])}\");",
            f"   function Compare_Greater_{vector} is new SSE2_Compare_128 ({vector}, {bits}, \"{x86_ada_instruction((signed_gt if signed else unsigned_gt)[bits])}\");",
            f"   function Native_Select_{vector} is new SSE2_Select_128 ({vector}, {bits});",
            f"   function Zero return {vector} is (Flyology_SIMD.Zero);",
            call("Splat", vector, "Value", f"Value : {scalar}"),
            call("From_Lanes", vector, "Values", f"Values : {vals}"),
            call("To_Lanes", vals, "Value", f"Value : {vector}"),
            call("Extract", scalar, "Value, Lane", f"Value : {vector}; Lane : {idx}"),
            call("Replace", vector, "Value, Lane, With_Value", f"Value : {vector}; Lane : {idx}; With_Value : {scalar}"),
        ]
        if bits > 16:
            out += [
                call("Add_Saturate", vector, "Left, Right", f"Left, Right : {vector}"),
                call("Subtract_Saturate", vector, "Left, Right", f"Left, Right : {vector}"),
            ]
        out += [
            f"   function Native_SHL_{vector} is new SSE2_Shift_128 ({vector}, \"{x86_ada_instruction(shift_left[bits])}\");",
            f"   function Native_SHR_{vector} is new SSE2_Shift_128 ({vector}, \"{x86_ada_instruction(shift_right[bits])}\");",
            f"   function Shift_Left_Logical (Value : {vector}; Count : Natural) return {vector} is (if Count >= {bits} then Flyology_SIMD.Zero else Native_SHL_{vector} (Value, Interfaces.Unsigned_32 (Count)));",
            f"   function Shift_Right_Logical (Value : {vector}; Count : Natural) return {vector} is (if Count >= {bits} then Flyology_SIMD.Zero else Native_SHR_{vector} (Value, Interfaces.Unsigned_32 (Count)));",
        ]
        if signed:
            if bits < 64:
                out += [
                    f"   function Native_SAR_{vector} is new SSE2_Shift_128 ({vector}, \"{x86_ada_instruction(shift_arithmetic[bits])}\");",
                    f"   function Shift_Right_Arithmetic (Value : {vector}; Count : Natural) return {vector} is (if Count >= {bits} then Flyology_SIMD.Shift_Right_Arithmetic (Value, Count) else Native_SAR_{vector} (Value, Interfaces.Unsigned_32 (Count)));",
                ]
            else:
                out.append(call("Shift_Right_Arithmetic", vector, "Value, Count", f"Value : {vector}; Count : Natural"))
        out += [
            f"   function Equal (Left, Right : {vector}) return {mask} is (Mask_From_Bit_Mask ({bit(f'Compare_Equal_{vector} (Left, Right, {sign})')}));",
            f"   function Greater_Than (Left, Right : {vector}) return {mask} is (Mask_From_Bit_Mask ({bit(f'Compare_Greater_{vector} (Left, Right, {sign})')}));",
            f"   function Greater_Equal (Left, Right : {vector}) return {mask} is (Mask_From_Bit_Mask ({bit(f'Compare_Greater_{vector} (Left, Right, {sign}) or Compare_Equal_{vector} (Left, Right, {sign})')}));",
            f"   function Less_Than (Left, Right : {vector}) return {mask} is (Greater_Than (Left => Right, Right => Left));",
            f"   function Less_Equal (Left, Right : {vector}) return {mask} is (Greater_Equal (Left => Right, Right => Left));",
            f"   function Select_Value (Mask : {mask}; If_True, If_False : {vector}) return {vector} is (Native_Select_{vector} ({'To_Bit_Mask (Mask)' if lanes == 16 else 'Interfaces.Unsigned_16 (To_Bit_Mask (Mask))'}, {weights}, If_True, If_False));",
        ]
        if "Min" not in instructions:
            out += [
                f"   function Min (Left, Right : {vector}) return {vector} is (Select_Value (Less_Than (Left, Right), Left, Right));",
                f"   function Max (Left, Right : {vector}) return {vector} is (Select_Value (Greater_Than (Left, Right), Left, Right));",
            ]
        out += [
            call("Reduce_Add_Wrap", scalar, "Value", f"Value : {vector}"),
            call("Reduce_Min", scalar, "Value", f"Value : {vector}"),
            call("Reduce_Max", scalar, "Value", f"Value : {vector}"),
        ]
        out += x86_memory_body(vector, arr, count)

    for vector, scalar, bits, lanes in FLOAT_TYPES:
        idx, vals, mask = lane_index(bits, lanes), lane_values(vector), mask_for(bits, lanes)
        arr, count = array_name(scalar), lane_count(bits, lanes)
        suffix = "ps" if bits == 32 else "pd"
        weights = f"Weights_X86_{bits}'Address"
        arithmetic = {"Add": "add", "Subtract": "sub", "Multiply": "mul", "Divide": "div"}
        for name, op in arithmetic.items():
            out += [f"   function Native_{name}_{vector} is new SSE2_Binary_128 ({vector}, \"{op}{suffix} %%xmm1, %%xmm0\");", f"   function {name} (Left, Right : {vector}) return {vector} is (Native_{name}_{vector} (Left, Right));"]
        for name, instruction in (("Interleave_Low", f"unpckl{suffix}"), ("Interleave_High", f"unpckh{suffix}")):
            out += [f"   function Native_{name}_{vector} is new SSE2_Binary_128 ({vector}, \"{instruction} %%xmm1, %%xmm0\");", f"   function {name} (Left, Right : {vector}) return {vector} is (Native_{name}_{vector} (Left, Right));"]
        for name, instruction in (("Deinterleave_Even", deinterleave[bits][0]), ("Deinterleave_Odd", deinterleave[bits][1])):
            out += [f"   function Native_{name}_{vector} is new SSE2_Binary_128 ({vector}, \"{x86_ada_instruction(instruction)}\");", f"   function {name} (Left, Right : {vector}) return {vector} is (Native_{name}_{vector} (Left, Right));"]
        reverse_float = reverse[bits]
        out += [
            f"   function Native_Reverse_{vector} is new SSE2_Unary_128 ({vector}, \"{x86_ada_instruction(reverse_float)}\");",
            f"   function Reverse_Lanes (Value : {vector}) return {vector} is (Native_Reverse_{vector} (Value));",
        ]
        compare_ops = (("Equal", "cmpeq"), ("Less_Than", "cmplt"), ("Less_Equal", "cmple"), ("Unordered", "cmpunord"))
        for name, op in compare_ops:
            out += [
                f"   function Compare_{name}_{vector} is new SSE2_Compare_128 ({vector}, {bits}, \"{op}{suffix} %%xmm1, %%xmm0\");",
                f"   function {name} (Left, Right : {vector}) return {mask} is (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Compare_{name}_{vector} (Left, Right, Sign_32'Address))));",
            ]
        out += [
            f"   function Greater_Than (Left, Right : {vector}) return {mask} is (Less_Than (Left => Right, Right => Left));",
            f"   function Greater_Equal (Left, Right : {vector}) return {mask} is (Less_Equal (Left => Right, Right => Left));",
            f"   function Native_Select_{vector} is new SSE2_Select_128 ({vector}, {bits});",
            f"   function Select_Value (Mask : {mask}; If_True, If_False : {vector}) return {vector} is (Native_Select_{vector} (Interfaces.Unsigned_16 (To_Bit_Mask (Mask)), {weights}, If_True, If_False));",
            f"   function Zero return {vector} is (Flyology_SIMD.Zero);",
            call("Splat", vector, "Value", f"Value : {scalar}"), call("From_Lanes", vector, "Values", f"Values : {vals}"),
            call("To_Lanes", vals, "Value", f"Value : {vector}"), call("Extract", scalar, "Value, Lane", f"Value : {vector}; Lane : {idx}"),
            call("Replace", vector, "Value, Lane, With_Value", f"Value : {vector}; Lane : {idx}; With_Value : {scalar}"),
            call("Min_Number", vector, "Left, Right", f"Left, Right : {vector}"),
            call("Max_Number", vector, "Left, Right", f"Left, Right : {vector}"),
            call("Reduce_Add", scalar, "Value", f"Value : {vector}"),
        ]
        out += x86_memory_body(vector, arr, count)

    for bits, lanes, storage in MASKS:
        mask, idx, count = mask_for(bits, lanes), lane_index(bits, lanes), lane_count(bits, lanes)
        st = f"Interfaces.{storage}"
        out += [call("Mask_From_Bit_Mask", mask, "Bits", f"Bits : {st}"), call("To_Bit_Mask", st, "Mask", f"Mask : {mask}"), call("Mask_And", mask, "Left, Right", f"Left, Right : {mask}"), call("Mask_Or", mask, "Left, Right", f"Left, Right : {mask}"), call("Mask_Xor", mask, "Left, Right", f"Left, Right : {mask}"), call("Mask_Not", mask, "Value", f"Value : {mask}"), call("Test", "Boolean", "Mask, Lane", f"Mask : {mask}; Lane : {idx}"), call("Any_True", "Boolean", "Mask", f"Mask : {mask}"), call("All_True", "Boolean", "Mask", f"Mask : {mask}"), call("None_True", "Boolean", "Mask", f"Mask : {mask}"), call("Population_Count", count, "Mask", f"Mask : {mask}")]
    return "\n".join(out)


def test_program() -> str:
    lines = [
        "with Ada.Command_Line;", "with Ada.Exceptions;", "with Ada.Text_IO;",
        "with Ada.Unchecked_Conversion;", "with Interfaces;", "with Flyology_SIMD;",
        "with Flyology_SIMD.Backends.Native;", "",
        "procedure Family_Tests is", "   use Ada.Text_IO;", "   use Flyology_SIMD;",
        "   use type Interfaces.Unsigned_8;", "   use type Interfaces.Unsigned_16;",
        "   use type Interfaces.Unsigned_32;", "   use type Interfaces.Unsigned_64;",
        "   use type Interfaces.Integer_8;", "   use type Interfaces.Integer_16;",
        "   use type Interfaces.Integer_32;", "   use type Interfaces.Integer_64;",
        "   use type Interfaces.IEEE_Float_32;", "   use type Interfaces.IEEE_Float_64;",
        "   Seed : constant Interfaces.Unsigned_64 := 16#5EED_0123_D15C_A11A#;",
        "   State : Interfaces.Unsigned_64 := Seed;",
        "   Failures : Natural := 0;", "   procedure Check (Condition : Boolean; Message : String) is",
        "   begin if not Condition then Failures := Failures + 1; Put_Line (\"FAIL: \" & Message); end if; end Check;", "",
        "   function Next_U64 return Interfaces.Unsigned_64 is",
        "   begin",
        "      State := State xor Interfaces.Shift_Left (State, 13);",
        "      State := State xor Interfaces.Shift_Right (State, 7);",
        "      State := State xor Interfaces.Shift_Left (State, 17);",
        "      return State;",
        "   end Next_U64;", "",
        "   function Reference_Popcount (Value : Natural) return Natural is",
        "      Bits : Natural := Value;",
        "      Count : Natural := 0;",
        "   begin",
        "      while Bits /= 0 loop Count := Count + Bits mod 2; Bits := Bits / 2; end loop;",
        "      return Count;",
        "   end Reference_Popcount;", "",
    ]
    for vector, scalar, bits, lanes, signed in INTEGER_TYPES:
        vals, arr, count = lane_values(vector), array_name(scalar), lane_count(bits, lanes)
        mask = mask_for(bits, lanes)
        mask_storage = "Interfaces.Unsigned_16" if lanes == 16 else "Interfaces.Unsigned_8"
        if signed:
            av = [f"{scalar}'First", "-1", "0", "1", f"{scalar}'Last"]
            bv = ["1", f"{scalar}'Last", "-1", f"{scalar}'First", "0"]
        else:
            av = ["0", "1", f"{scalar}'Last", f"2 ** ({bits - 1})", "17"]
            bv = ["1", f"{scalar}'Last", "2", f"2 ** ({bits - 1}) - 1", "9"]
        agg_a = ", ".join(av[n % len(av)] for n in range(lanes))
        agg_b = ", ".join(bv[n % len(bv)] for n in range(lanes))
        unsigned = f"Interfaces.Unsigned_{bits}"
        random_bits = (
            "Next_U64"
            if bits == 64
            else f"{unsigned} (Next_U64 and 16#{((1 << bits) - 1):X}#)"
        )
        if signed:
            random_lane = f"Bits_To_{vector} ({random_bits})"
            helpers = [
                f"   function Bits_To_{vector} is new Ada.Unchecked_Conversion ({unsigned}, {scalar});",
                f"   function {vector}_To_Bits is new Ada.Unchecked_Conversion ({scalar}, {unsigned});",
            ]
            add_oracle = f"Bits_To_{vector} ({vector}_To_Bits (Extract (R_A, Lane)) + {vector}_To_Bits (Extract (R_B, Lane)))"
            sub_oracle = f"Bits_To_{vector} ({vector}_To_Bits (Extract (R_A, Lane)) - {vector}_To_Bits (Extract (R_B, Lane)))"
            mul_oracle = f"Bits_To_{vector} ({vector}_To_Bits (Extract (R_A, Lane)) * {vector}_To_Bits (Extract (R_B, Lane)))"
            and_oracle = f"(Bits_To_{vector} ({vector}_To_Bits (Extract (R_A, Lane)) and {vector}_To_Bits (Extract (R_B, Lane))))"
            or_oracle = f"(Bits_To_{vector} ({vector}_To_Bits (Extract (R_A, Lane)) or {vector}_To_Bits (Extract (R_B, Lane))))"
            xor_oracle = f"(Bits_To_{vector} ({vector}_To_Bits (Extract (R_A, Lane)) xor {vector}_To_Bits (Extract (R_B, Lane))))"
            not_oracle = f"(Bits_To_{vector} (not {vector}_To_Bits (Extract (R_A, Lane))))"
            add_sat_body = [
                f"      if Right > 0 and then Left > {scalar}'Last - Right then return {scalar}'Last;",
                f"      elsif Right < 0 and then Left < {scalar}'First - Right then return {scalar}'First;",
                "      else return Left + Right; end if;",
            ]
            sub_sat_body = [
                f"      if Right < 0 and then Left > {scalar}'Last + Right then return {scalar}'Last;",
                f"      elsif Right > 0 and then Left < {scalar}'First + Right then return {scalar}'First;",
                "      else return Left - Right; end if;",
            ]
            reduce_return = f"Bits_To_{vector} (Accumulator)"
            reduce_term = f"{vector}_To_Bits (Extract (Value, Lane))"
            shl_oracle = f"Bits_To_{vector} (Interfaces.Shift_Left ({vector}_To_Bits (Extract (A, Lane)), 1))"
            shr_oracle = f"Bits_To_{vector} (Interfaces.Shift_Right ({vector}_To_Bits (Extract (A, Lane)), 1))"
            sar_oracle = "(if Extract (A, Lane) >= 0 then Extract (A, Lane) / 2 else -1 - ((-1 - Extract (A, Lane)) / 2))"
        else:
            random_lane = random_bits
            helpers = []
            add_oracle = "Extract (R_A, Lane) + Extract (R_B, Lane)"
            sub_oracle = "Extract (R_A, Lane) - Extract (R_B, Lane)"
            mul_oracle = "Extract (R_A, Lane) * Extract (R_B, Lane)"
            and_oracle = "(Extract (R_A, Lane) and Extract (R_B, Lane))"
            or_oracle = "(Extract (R_A, Lane) or Extract (R_B, Lane))"
            xor_oracle = "(Extract (R_A, Lane) xor Extract (R_B, Lane))"
            not_oracle = "(not Extract (R_A, Lane))"
            add_sat_body = [
                f"      if Left > {scalar}'Last - Right then return {scalar}'Last;",
                "      else return Left + Right; end if;",
            ]
            sub_sat_body = [
                "      if Left < Right then return 0;",
                "      else return Left - Right; end if;",
            ]
            reduce_return = f"{scalar} (Accumulator)"
            reduce_term = f"{unsigned} (Extract (Value, Lane))"
            shl_oracle = f"{scalar} (Interfaces.Shift_Left ({unsigned} (Extract (A, Lane)), 1))"
            shr_oracle = f"{scalar} (Interfaces.Shift_Right ({unsigned} (Extract (A, Lane)), 1))"
            sar_oracle = None
        lines += [
            *helpers,
            f"   function Reference_Add_Saturate_{vector} (Left, Right : {scalar}) return {scalar} is",
            "   begin",
            *add_sat_body,
            f"   end Reference_Add_Saturate_{vector};",
            f"   function Reference_Subtract_Saturate_{vector} (Left, Right : {scalar}) return {scalar} is",
            "   begin",
            *sub_sat_body,
            f"   end Reference_Subtract_Saturate_{vector};",
            f"   function Reference_Reduce_Add_{vector} (Value : {vector}) return {scalar} is",
            f"      Accumulator : {unsigned} := 0;",
            "   begin",
            f"      for Lane in {lane_index(bits, lanes)} loop Accumulator := Accumulator + {reduce_term}; end loop;",
            f"      return {reduce_return};",
            f"   end Reference_Reduce_Add_{vector};",
            f"   function Reference_Reduce_Min_{vector} (Value : {vector}) return {scalar} is",
            f"      Result : {scalar} := Extract (Value, {lane_index(bits, lanes)}'First);",
            "   begin",
            f"      for Lane in {lane_index(bits, lanes)} loop if Extract (Value, Lane) < Result then Result := Extract (Value, Lane); end if; end loop;",
            "      return Result;",
            f"   end Reference_Reduce_Min_{vector};",
            f"   function Reference_Reduce_Max_{vector} (Value : {vector}) return {scalar} is",
            f"      Result : {scalar} := Extract (Value, {lane_index(bits, lanes)}'First);",
            "   begin",
            f"      for Lane in {lane_index(bits, lanes)} loop if Extract (Value, Lane) > Result then Result := Extract (Value, Lane); end if; end loop;",
            "      return Result;",
            f"   end Reference_Reduce_Max_{vector};",
            f"   function Random_{vector}_Lanes return {vals} is",
            f"      Result : {vals};",
            "   begin",
            f"      for Lane in {lane_index(bits, lanes)} loop Result (Lane) := {random_lane}; end loop;",
            "      return Result;",
            f"   end Random_{vector}_Lanes;",
            f"   function Same (Left, Right : {vector}) return Boolean is (To_Lanes (Left) = To_Lanes (Right));",
            f"   procedure Test_{vector} is",
            f"      A : constant {vector} := From_Lanes ([{agg_a}]);",
            f"      B : constant {vector} := From_Lanes ([{agg_b}]);",
            f"      Data, Reference : {arr} (0 .. {lanes + 5}) := [others => 0];",
            f"      Aligned_Data : {arr} (0 .. {lanes - 1}) := [others => 0] with Alignment => 16;",
            "   begin",
            f"      Check (To_Lanes (A) = [{agg_a}], \"{vector} scalar lane construction\");",
            f"      Check (Same ({vector}'(Backends.Native.Zero), {vector}'(Zero)) and then Same ({vector}'(Backends.Native.Splat (To_Lanes (A) (0))), {vector}'(Splat (To_Lanes (A) (0)))), \"{vector} native construction\");",
            f"      Check (Same (Backends.Native.From_Lanes (To_Lanes (A)), A) and then Backends.Native.To_Lanes (A) = To_Lanes (A), \"{vector} native lane roundtrip\");",
            f"      for Lane in {lane_index(bits, lanes)} loop",
            f"         Check (Extract (A, Lane) = To_Lanes (A) (Lane), \"{vector} scalar extract\" & Lane'Image);",
            f"         Check (Extract (Replace (A, Lane, To_Lanes (B) (Lane)), Lane) = To_Lanes (B) (Lane), \"{vector} scalar replace\" & Lane'Image);",
            f"         Check (Backends.Native.Extract (A, Lane) = Extract (A, Lane) and then Same (Backends.Native.Replace (A, Lane, To_Lanes (B) (Lane)), Replace (A, Lane, To_Lanes (B) (Lane))), \"{vector} native lane access\" & Lane'Image);",
            "      end loop;",
        ]
        for name in ("Add_Wrap", "Subtract_Wrap", "Multiply_Wrap", "Add_Saturate", "Subtract_Saturate", "Bitwise_And", "Bitwise_Or", "Bitwise_Xor", "Min", "Max", "Interleave_Low", "Interleave_High", "Deinterleave_Even", "Deinterleave_Odd"):
            lines.append(f"      Check (Same (Backends.Native.{name} (A, B), {name} (A, B)), \"{vector} {name}\");")
        lines += [
            f"      Check (Same (Backends.Native.Bitwise_Not (A), Bitwise_Not (A)), \"{vector} not\");",
            f"      Check (Same (Backends.Native.Reverse_Lanes (A), Reverse_Lanes (A)), \"{vector} reverse\");",
            f"      for Shift in Natural range 0 .. {bits + 2} loop",
            f"         Check (Same (Backends.Native.Shift_Left_Logical (A, Shift), Shift_Left_Logical (A, Shift)), \"{vector} shl\" & Shift'Image);",
            f"         Check (Same (Backends.Native.Shift_Right_Logical (A, Shift), Shift_Right_Logical (A, Shift)), \"{vector} shr\" & Shift'Image);",
        ]
        if signed:
            lines.append(f"         Check (Same (Backends.Native.Shift_Right_Arithmetic (A, Shift), Shift_Right_Arithmetic (A, Shift)), \"{vector} sar\" & Shift'Image);")
        lines += [
            "      end loop;",
            f"      Check (Same (Shift_Left_Logical (A, {bits}), Zero) and then Same (Shift_Right_Logical (A, {bits}), Zero), \"{vector} independent oversized logical shifts\");",
            f"      for Lane in {lane_index(bits, lanes)} loop",
            f"         Check (Extract (Shift_Left_Logical (A, 1), Lane) = {shl_oracle} and then Extract (Shift_Right_Logical (A, 1), Lane) = {shr_oracle}, \"{vector} independent logical shift\" & Lane'Image);",
        ]
        if signed:
            lines.append(f"         Check (Extract (Shift_Right_Arithmetic (A, 1), Lane) = {sar_oracle}, \"{vector} independent arithmetic shift\" & Lane'Image);")
            lines.append(f"         Check (Extract (Shift_Right_Arithmetic (A, {bits}), Lane) = (if Extract (A, Lane) < 0 then -1 else 0), \"{vector} independent oversized arithmetic shift\" & Lane'Image);")
        lines += [
            "      end loop;",
            f"      for Lane in {lane_index(bits, lanes)} loop",
            f"         Check (Extract (Reverse_Lanes (A), Lane) = Extract (A, {lane_index(bits, lanes)} ({lanes - 1} - Lane)), \"{vector} independent reverse\" & Lane'Image);",
            f"         Check (Extract (Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, {lane_index(bits, lanes)} (Lane / 2)) else Extract (B, {lane_index(bits, lanes)} (Lane / 2))), \"{vector} independent interleave low\" & Lane'Image);",
            f"         Check (Extract (Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, {lane_index(bits, lanes)} ({lanes // 2} + Lane / 2)) else Extract (B, {lane_index(bits, lanes)} ({lanes // 2} + Lane / 2))), \"{vector} independent interleave high\" & Lane'Image);",
            f"         Check (Extract (Deinterleave_Even (A, B), Lane) = (if Lane < {lanes // 2} then Extract (A, {lane_index(bits, lanes)} (2 * Lane)) else Extract (B, {lane_index(bits, lanes)} (2 * (Lane - {lanes // 2})))), \"{vector} independent deinterleave even\" & Lane'Image);",
            f"         Check (Extract (Deinterleave_Odd (A, B), Lane) = (if Lane < {lanes // 2} then Extract (A, {lane_index(bits, lanes)} (2 * Lane + 1)) else Extract (B, {lane_index(bits, lanes)} (2 * (Lane - {lanes // 2}) + 1))), \"{vector} independent deinterleave odd\" & Lane'Image);",
            "      end loop;",
        ]
        for name in ("Equal", "Less_Than", "Less_Equal", "Greater_Than", "Greater_Equal"):
            lines.append(f"      Check (Backends.Native.To_Bit_Mask (Backends.Native.{name} (A, B)) = Flyology_SIMD.To_Bit_Mask ({name} (A, B)), \"{vector} {name}\");")
        lines += [
            f"      Check (Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), \"{vector} select\");",
            f"      for Pattern in Natural range 0 .. 2 ** {lanes} - 1 loop",
            f"         Check (Backends.Native.To_Bit_Mask ({mask}'(Backends.Native.Mask_From_Bit_Mask ({mask_storage} (Pattern)))) = {mask_storage} (Pattern), \"{vector} mask roundtrip\" & Pattern'Image);",
            f"         Check (Any_True ({mask}'(Mask_From_Bit_Mask ({mask_storage} (Pattern)))) = (Pattern /= 0) and then None_True ({mask}'(Mask_From_Bit_Mask ({mask_storage} (Pattern)))) = (Pattern = 0) and then All_True ({mask}'(Mask_From_Bit_Mask ({mask_storage} (Pattern)))) = (Pattern = 2 ** {lanes} - 1), \"{vector} scalar mask predicates\" & Pattern'Image);",
            f"         Check (Population_Count ({mask}'(Mask_From_Bit_Mask ({mask_storage} (Pattern)))) = Reference_Popcount (Pattern), \"{vector} scalar mask population\" & Pattern'Image);",
            f"         Check (To_Bit_Mask (Mask_Not ({mask}'(Mask_From_Bit_Mask ({mask_storage} (Pattern))))) = {mask_storage} (2 ** {lanes} - 1 - Pattern), \"{vector} scalar mask not\" & Pattern'Image);",
            f"         Check (To_Bit_Mask (Mask_And ({mask}'(Mask_From_Bit_Mask ({mask_storage} (Pattern))), Mask_From_Bit_Mask ({mask_storage} (2 ** {lanes} - 1 - Pattern)))) = 0 and then To_Bit_Mask (Mask_Or ({mask}'(Mask_From_Bit_Mask ({mask_storage} (Pattern))), Mask_From_Bit_Mask ({mask_storage} (2 ** {lanes} - 1 - Pattern)))) = {mask_storage} (2 ** {lanes} - 1) and then To_Bit_Mask (Mask_Xor ({mask}'(Mask_From_Bit_Mask ({mask_storage} (Pattern))), Mask_From_Bit_Mask ({mask_storage} (2 ** {lanes} - 1 - Pattern)))) = {mask_storage} (2 ** {lanes} - 1), \"{vector} scalar mask algebra\" & Pattern'Image);",
            f"         Check (Backends.Native.Any_True ({mask}'(Backends.Native.Mask_From_Bit_Mask ({mask_storage} (Pattern)))) = (Pattern /= 0) and then Backends.Native.None_True ({mask}'(Backends.Native.Mask_From_Bit_Mask ({mask_storage} (Pattern)))) = (Pattern = 0) and then Backends.Native.All_True ({mask}'(Backends.Native.Mask_From_Bit_Mask ({mask_storage} (Pattern)))) = (Pattern = 2 ** {lanes} - 1) and then Backends.Native.Population_Count ({mask}'(Backends.Native.Mask_From_Bit_Mask ({mask_storage} (Pattern)))) = Reference_Popcount (Pattern), \"{vector} native mask reductions\" & Pattern'Image);",
            f"         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_Not ({mask}'(Backends.Native.Mask_From_Bit_Mask ({mask_storage} (Pattern))))) = {mask_storage} (2 ** {lanes} - 1 - Pattern), \"{vector} native mask not\" & Pattern'Image);",
            f"         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_And ({mask}'(Backends.Native.Mask_From_Bit_Mask ({mask_storage} (Pattern))), Backends.Native.Mask_From_Bit_Mask ({mask_storage} (2 ** {lanes} - 1 - Pattern)))) = 0 and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Or ({mask}'(Backends.Native.Mask_From_Bit_Mask ({mask_storage} (Pattern))), Backends.Native.Mask_From_Bit_Mask ({mask_storage} (2 ** {lanes} - 1 - Pattern)))) = {mask_storage} (2 ** {lanes} - 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Xor ({mask}'(Backends.Native.Mask_From_Bit_Mask ({mask_storage} (Pattern))), Backends.Native.Mask_From_Bit_Mask ({mask_storage} (2 ** {lanes} - 1 - Pattern)))) = {mask_storage} (2 ** {lanes} - 1), \"{vector} native mask algebra\" & Pattern'Image);",
            f"         for Lane in {lane_index(bits, lanes)} loop Check (Backends.Native.Test ({mask}'(Backends.Native.Mask_From_Bit_Mask ({mask_storage} (Pattern))), Lane) = Test ({mask}'(Mask_From_Bit_Mask ({mask_storage} (Pattern))), Lane), \"{vector} native mask lane\" & Pattern'Image & Lane'Image); end loop;",
            f"         Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask ({mask_storage} (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask ({mask_storage} (Pattern)), A, B)), \"{vector} exhaustive select\" & Pattern'Image);",
            f"         for Lane in {lane_index(bits, lanes)} loop Check (Extract (Select_Value (Mask_From_Bit_Mask ({mask_storage} (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)), \"{vector} independent select\" & Pattern'Image & Lane'Image); end loop;",
            "      end loop;",
            f"      Check (Reduce_Add_Wrap (A) = Reference_Reduce_Add_{vector} (A) and then Backends.Native.Reduce_Add_Wrap (A) = Reference_Reduce_Add_{vector} (A), \"{vector} independent reduce add\");",
            f"      Check (Reduce_Min (A) = Reference_Reduce_Min_{vector} (A) and then Backends.Native.Reduce_Min (A) = Reference_Reduce_Min_{vector} (A), \"{vector} independent reduce min\");",
            f"      Check (Reduce_Max (A) = Reference_Reduce_Max_{vector} (A) and then Backends.Native.Reduce_Max (A) = Reference_Reduce_Max_{vector} (A), \"{vector} independent reduce max\");",
            f"      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);",
            f"      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), \"{vector} full memory\");",
            f"      for Lane in {lane_index(bits, lanes)} loop Check (Data (1 + Lane) = Extract (A, Lane), \"{vector} independent full store\" & Lane'Image); end loop;",
            f"      Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store (Data, 1, B); Store (Reference, 1, B);",
            f"      Check (Data = Reference and then Same (Backends.Native.Load (Data, 1), Load (Data, 1)), \"{vector} ordinary memory\");",
            f"      Check (Backends.Native.Is_Aligned_16 (Aligned_Data, 0), \"{vector} native alignment predicate\");",
            f"      Backends.Native.Store_Aligned (Aligned_Data, 0, A);",
            f"      Check (Same (Backends.Native.Load_Aligned (Aligned_Data, 0), A), \"{vector} aligned memory\");",
            f"      for N in {count} loop",
            "         Data := [others => 0]; Reference := [others => 0];",
            f"         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);",
            f"         for Index in Data'Range loop Check (Data (Index) = (if Index in 2 .. 2 + N - 1 then Extract (B, {lane_index(bits, lanes)} (Index - 2)) else 0), \"{vector} independent partial store\" & N'Image & Index'Image); end loop;",
            f"         Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, N), Load_Partial (Data, 2, N)), \"{vector} partial\" & N'Image);",
            "         declare",
            f"            Exact : {arr} (1 .. N) := [others => 0];",
            "         begin",
            f"            Check (Same (Backends.Native.Load_Partial (Exact, 1, N), Load_Partial (Exact, 1, N)), \"{vector} exact-extent partial load\" & N'Image);",
            f"            Backends.Native.Store_Partial (Exact, 1, N, B);",
            "         end;",
            "      end loop;",
            "      for Iteration in 1 .. 250 loop",
            "         declare",
            f"            R_A : constant {vector} := From_Lanes (Random_{vector}_Lanes);",
            f"            R_B : constant {vector} := From_Lanes (Random_{vector}_Lanes);",
            "         begin",
            f"            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), \"{vector} randomized arithmetic\");",
            f"            Check (Same (Backends.Native.Add_Saturate (R_A, R_B), Add_Saturate (R_A, R_B)) and then Same (Backends.Native.Subtract_Saturate (R_A, R_B), Subtract_Saturate (R_A, R_B)), \"{vector} randomized native saturation\");",
            f"            Check (Same (Backends.Native.Bitwise_And (R_A, R_B), Bitwise_And (R_A, R_B)) and then Same (Backends.Native.Bitwise_Or (R_A, R_B), Bitwise_Or (R_A, R_B)) and then Same (Backends.Native.Bitwise_Xor (R_A, R_B), Bitwise_Xor (R_A, R_B)) and then Same (Backends.Native.Bitwise_Not (R_A), Bitwise_Not (R_A)), \"{vector} randomized native bitwise\");",
            f"            Check (Same (Backends.Native.Min (R_A, R_B), Min (R_A, R_B)) and then Same (Backends.Native.Max (R_A, R_B), Max (R_A, R_B)), \"{vector} randomized native min/max\");",
            f"            Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (R_A, R_B)), \"{vector} randomized native comparisons\");",
            f"            for Lane in {lane_index(bits, lanes)} loop",
            f"               Check (Extract (Add_Wrap (R_A, R_B), Lane) = {add_oracle}, \"{vector} independent add oracle\" & Lane'Image);",
            f"               Check (Extract (Subtract_Wrap (R_A, R_B), Lane) = {sub_oracle}, \"{vector} independent subtract oracle\" & Lane'Image);",
            f"               Check (Extract (Multiply_Wrap (R_A, R_B), Lane) = {mul_oracle}, \"{vector} independent multiply oracle\" & Lane'Image);",
            f"               Check (Extract (Add_Saturate (R_A, R_B), Lane) = Reference_Add_Saturate_{vector} (Extract (R_A, Lane), Extract (R_B, Lane)) and then Extract (Subtract_Saturate (R_A, R_B), Lane) = Reference_Subtract_Saturate_{vector} (Extract (R_A, Lane), Extract (R_B, Lane)), \"{vector} independent saturation oracle\" & Lane'Image);",
            f"               Check (Extract (Bitwise_And (R_A, R_B), Lane) = {and_oracle} and then Extract (Bitwise_Or (R_A, R_B), Lane) = {or_oracle} and then Extract (Bitwise_Xor (R_A, R_B), Lane) = {xor_oracle} and then Extract (Bitwise_Not (R_A), Lane) = {not_oracle}, \"{vector} independent bitwise oracle\" & Lane'Image);",
            f"               Check (Extract (Min (R_A, R_B), Lane) = (if Extract (R_A, Lane) < Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)) and then Extract (Max (R_A, R_B), Lane) = (if Extract (R_A, Lane) > Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)), \"{vector} independent min/max oracle\" & Lane'Image);",
            f"               Check (Test (Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) = Extract (R_B, Lane)) and then Test (Less_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) < Extract (R_B, Lane)) and then Test (Less_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) <= Extract (R_B, Lane)) and then Test (Greater_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) > Extract (R_B, Lane)) and then Test (Greater_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) >= Extract (R_B, Lane)), \"{vector} independent comparison oracle\" & Lane'Image);",
            "            end loop;",
            "         end;",
            "      end loop;",
            f"   end Test_{vector};", "",
        ]
    for vector, scalar, bits, lanes in FLOAT_TYPES:
        vals, arr, count = lane_values(vector), array_name(scalar), lane_count(bits, lanes)
        mask = mask_for(bits, lanes)
        av = ["0.0", "-0.0", "1.5", "-2.25", "17.0"]
        bv = ["2.0", "-3.0", "0.5", "4.0", "-1.0"]
        agg_a = ", ".join(av[n % len(av)] for n in range(lanes))
        agg_b = ", ".join(bv[n % len(bv)] for n in range(lanes))
        uint = f"Interfaces.Unsigned_{bits}"
        lines += [
            f"   function Random_{vector}_Lanes return {vals} is",
            f"      Result : {vals};",
            "      Raw : Interfaces.Integer_64;",
            "   begin",
            f"      for Lane in {lane_index(bits, lanes)} loop",
            "         Raw := Interfaces.Integer_64 (Next_U64 mod 2_000_001) - 1_000_000;",
            f"         Result (Lane) := {scalar} (Raw) / 128.0;",
            "      end loop;",
            "      return Result;",
            f"   end Random_{vector}_Lanes;",
            f"   function Bits_{vector} is new Ada.Unchecked_Conversion ({scalar}, {uint});",
            f"   function Same (Left, Right : {vector}) return Boolean is",
            f"      L : constant {vals} := To_Lanes (Left);",
            f"      R : constant {vals} := To_Lanes (Right);",
            "   begin",
            f"      for Lane in {lane_index(bits, lanes)} loop",
            f"         if Bits_{vector} (L (Lane)) /= Bits_{vector} (R (Lane)) then return False; end if;",
            "      end loop;",
            "      return True;",
            "   end Same;",
            f"   function Reference_Reduce_Add_{vector} (Value : {vector}) return {scalar} is",
            f"      Result : {scalar} := 0.0;",
            "   begin",
            f"      for Lane in {lane_index(bits, lanes)} loop Result := Result + Extract (Value, Lane); end loop;",
            "      return Result;",
            f"   end Reference_Reduce_Add_{vector};",
            f"   procedure Test_{vector} is",
            f"      A : constant {vector} := From_Lanes ([{agg_a}]);", f"      B : constant {vector} := From_Lanes ([{agg_b}]);",
            f"      Data, Reference : {arr} (0 .. {lanes + 5}) := [others => 0.0];",
            f"      Aligned_Data : {arr} (0 .. {lanes - 1}) := [others => 0.0] with Alignment => 16;", "   begin",
            f"      Check (Same (A, From_Lanes (To_Lanes (A))), \"{vector} scalar lane roundtrip\");",
            f"      Check (Same ({vector}'(Backends.Native.Zero), {vector}'(Zero)) and then Same ({vector}'(Backends.Native.Splat (To_Lanes (A) (0))), {vector}'(Splat (To_Lanes (A) (0)))), \"{vector} native construction\");",
            f"      Check (Same (Backends.Native.From_Lanes (To_Lanes (A)), A) and then Same (Backends.Native.From_Lanes (Backends.Native.To_Lanes (A)), A), \"{vector} native lane roundtrip\");",
            f"      for Lane in {lane_index(bits, lanes)} loop",
            f"         Check (Bits_{vector} (Extract (A, Lane)) = Bits_{vector} (To_Lanes (A) (Lane)), \"{vector} scalar extract\" & Lane'Image);",
            f"         Check (Bits_{vector} (Backends.Native.Extract (A, Lane)) = Bits_{vector} (Extract (A, Lane)) and then Same (Backends.Native.Replace (A, Lane, To_Lanes (B) (Lane)), Replace (A, Lane, To_Lanes (B) (Lane))), \"{vector} native lane access\" & Lane'Image);",
            "      end loop;",
        ]
        for name in ("Add", "Subtract", "Multiply", "Divide", "Min_Number", "Max_Number", "Interleave_Low", "Interleave_High", "Deinterleave_Even", "Deinterleave_Odd"):
            lines.append(f"      Check (Same (Backends.Native.{name} (A, B), {name} (A, B)), \"{vector} {name}\");")
        lines += [f"      Check (Same (Backends.Native.Reverse_Lanes (A), Reverse_Lanes (A)), \"{vector} reverse\");"]
        lines += [
            f"      for Lane in {lane_index(bits, lanes)} loop",
            f"         Check (Bits_{vector} (Extract (Add (A, B), Lane)) = Bits_{vector} (Extract (A, Lane) + Extract (B, Lane)) and then Bits_{vector} (Extract (Subtract (A, B), Lane)) = Bits_{vector} (Extract (A, Lane) - Extract (B, Lane)) and then Bits_{vector} (Extract (Multiply (A, B), Lane)) = Bits_{vector} (Extract (A, Lane) * Extract (B, Lane)), \"{vector} independent arithmetic\" & Lane'Image);",
            f"         Check (Bits_{vector} (Extract (Divide (A, B), Lane)) = Bits_{vector} (Extract (A, Lane) / Extract (B, Lane)), \"{vector} independent division\" & Lane'Image);",
            f"         Check (Extract (Reverse_Lanes (A), Lane) = Extract (A, {lane_index(bits, lanes)} ({lanes - 1} - Lane)), \"{vector} independent reverse\" & Lane'Image);",
            f"         Check (Extract (Interleave_Low (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, {lane_index(bits, lanes)} (Lane / 2)) else Extract (B, {lane_index(bits, lanes)} (Lane / 2))), \"{vector} independent interleave low\" & Lane'Image);",
            f"         Check (Extract (Interleave_High (A, B), Lane) = (if Lane mod 2 = 0 then Extract (A, {lane_index(bits, lanes)} ({lanes // 2} + Lane / 2)) else Extract (B, {lane_index(bits, lanes)} ({lanes // 2} + Lane / 2))), \"{vector} independent interleave high\" & Lane'Image);",
            f"         Check (Extract (Deinterleave_Even (A, B), Lane) = (if Lane < {lanes // 2} then Extract (A, {lane_index(bits, lanes)} (2 * Lane)) else Extract (B, {lane_index(bits, lanes)} (2 * (Lane - {lanes // 2})))), \"{vector} independent deinterleave even\" & Lane'Image);",
            f"         Check (Extract (Deinterleave_Odd (A, B), Lane) = (if Lane < {lanes // 2} then Extract (A, {lane_index(bits, lanes)} (2 * Lane + 1)) else Extract (B, {lane_index(bits, lanes)} (2 * (Lane - {lanes // 2}) + 1))), \"{vector} independent deinterleave odd\" & Lane'Image);",
            "      end loop;",
        ]
        for name in ("Equal", "Less_Than", "Less_Equal", "Greater_Than", "Greater_Equal", "Unordered"):
            lines.append(f"      Check (Backends.Native.To_Bit_Mask (Backends.Native.{name} (A, B)) = Flyology_SIMD.To_Bit_Mask ({name} (A, B)), \"{vector} {name}\");")
        lines += [
            f"      Check (Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), \"{vector} select\");",
            f"      for Pattern in Natural range 0 .. 2 ** {lanes} - 1 loop",
            f"         Check (Backends.Native.To_Bit_Mask ({mask}'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Interfaces.Unsigned_8 (Pattern), \"{vector} mask roundtrip\" & Pattern'Image);",
            f"         Check (Any_True ({mask}'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern /= 0) and then None_True ({mask}'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 0) and then All_True ({mask}'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 2 ** {lanes} - 1), \"{vector} scalar mask predicates\" & Pattern'Image);",
            f"         Check (Population_Count ({mask}'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Popcount (Pattern), \"{vector} scalar mask population\" & Pattern'Image);",
            f"         Check (To_Bit_Mask (Mask_Not ({mask}'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** {lanes} - 1 - Pattern), \"{vector} scalar mask not\" & Pattern'Image);",
            f"         Check (To_Bit_Mask (Mask_And ({mask}'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** {lanes} - 1 - Pattern)))) = 0 and then To_Bit_Mask (Mask_Or ({mask}'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** {lanes} - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** {lanes} - 1) and then To_Bit_Mask (Mask_Xor ({mask}'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** {lanes} - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** {lanes} - 1), \"{vector} scalar mask algebra\" & Pattern'Image);",
            f"         Check (Backends.Native.Any_True ({mask}'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern /= 0) and then Backends.Native.None_True ({mask}'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 0) and then Backends.Native.All_True ({mask}'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 2 ** {lanes} - 1) and then Backends.Native.Population_Count ({mask}'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Popcount (Pattern), \"{vector} native mask reductions\" & Pattern'Image);",
            f"         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_Not ({mask}'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** {lanes} - 1 - Pattern), \"{vector} native mask not\" & Pattern'Image);",
            f"         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_And ({mask}'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** {lanes} - 1 - Pattern)))) = 0 and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Or ({mask}'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** {lanes} - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** {lanes} - 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Xor ({mask}'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** {lanes} - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** {lanes} - 1), \"{vector} native mask algebra\" & Pattern'Image);",
            f"         for Lane in {lane_index(bits, lanes)} loop Check (Backends.Native.Test ({mask}'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane) = Test ({mask}'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane), \"{vector} native mask lane\" & Pattern'Image & Lane'Image); end loop;",
            f"         Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)), \"{vector} exhaustive select\" & Pattern'Image);",
            f"         for Lane in {lane_index(bits, lanes)} loop Check (Extract (Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)), \"{vector} independent select\" & Pattern'Image & Lane'Image); end loop;",
            "      end loop;",
            f"      Check (Bits_{vector} (Reduce_Add (A)) = Bits_{vector} (Reference_Reduce_Add_{vector} (A)) and then Bits_{vector} (Backends.Native.Reduce_Add (A)) = Bits_{vector} (Reference_Reduce_Add_{vector} (A)), \"{vector} independent reduce\");",
            f"      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);",
            f"      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), \"{vector} full memory\");",
            f"      for Lane in {lane_index(bits, lanes)} loop Check (Bits_{vector} (Data (1 + Lane)) = Bits_{vector} (Extract (A, Lane)), \"{vector} independent full store\" & Lane'Image); end loop;",
            f"      Data := [others => 0.0]; Reference := [others => 0.0]; Backends.Native.Store (Data, 1, B); Store (Reference, 1, B);",
            f"      Check (Data = Reference and then Same (Backends.Native.Load (Data, 1), Load (Data, 1)), \"{vector} ordinary memory\");",
            f"      Check (Backends.Native.Is_Aligned_16 (Aligned_Data, 0), \"{vector} native alignment predicate\");",
            f"      Backends.Native.Store_Aligned (Aligned_Data, 0, A);",
            f"      Check (Same (Backends.Native.Load_Aligned (Aligned_Data, 0), A), \"{vector} aligned memory\");",
            f"      for N in {count} loop",
            "         Data := [others => 0.0]; Reference := [others => 0.0];",
            f"         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);",
            f"         for Index in Data'Range loop Check (Bits_{vector} (Data (Index)) = Bits_{vector} ((if Index in 2 .. 2 + N - 1 then Extract (B, {lane_index(bits, lanes)} (Index - 2)) else 0.0)), \"{vector} independent partial store\" & N'Image & Index'Image); end loop;",
            f"         Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, N), Load_Partial (Data, 2, N)), \"{vector} partial\" & N'Image);",
            "         declare",
            f"            Exact : {arr} (1 .. N) := [others => 0.0];",
            "         begin",
            f"            Check (Same (Backends.Native.Load_Partial (Exact, 1, N), Load_Partial (Exact, 1, N)), \"{vector} exact-extent partial load\" & N'Image);",
            f"            Backends.Native.Store_Partial (Exact, 1, N, B);",
            "         end;",
            "      end loop;",
            "      for Iteration in 1 .. 250 loop",
            "         declare",
            f"            R_A : constant {vector} := From_Lanes (Random_{vector}_Lanes);",
            f"            R_B : constant {vector} := From_Lanes (Random_{vector}_Lanes);",
            "         begin",
            f"            Check (Same (Backends.Native.Add (R_A, R_B), Add (R_A, R_B)) and then Same (Backends.Native.Subtract (R_A, R_B), Subtract (R_A, R_B)) and then Same (Backends.Native.Multiply (R_A, R_B), Multiply (R_A, R_B)) and then Same (Backends.Native.Divide (R_A, R_B), Divide (R_A, R_B)), \"{vector} randomized native arithmetic\");",
            f"            Check (Same (Backends.Native.Min_Number (R_A, R_B), Min_Number (R_A, R_B)) and then Same (Backends.Native.Max_Number (R_A, R_B), Max_Number (R_A, R_B)), \"{vector} randomized native min/max\");",
            f"            Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Unordered (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Unordered (R_A, R_B)), \"{vector} randomized native comparisons\");",
            f"            for Lane in {lane_index(bits, lanes)} loop",
            f"               Check (Bits_{vector} (Extract (Add (R_A, R_B), Lane)) = Bits_{vector} (Extract (R_A, Lane) + Extract (R_B, Lane)) and then Bits_{vector} (Extract (Subtract (R_A, R_B), Lane)) = Bits_{vector} (Extract (R_A, Lane) - Extract (R_B, Lane)) and then Bits_{vector} (Extract (Multiply (R_A, R_B), Lane)) = Bits_{vector} (Extract (R_A, Lane) * Extract (R_B, Lane)), \"{vector} randomized independent arithmetic\" & Lane'Image);",
            f"               if Extract (R_B, Lane) /= 0.0 then Check (Bits_{vector} (Extract (Divide (R_A, R_B), Lane)) = Bits_{vector} (Extract (R_A, Lane) / Extract (R_B, Lane)), \"{vector} randomized independent division\" & Lane'Image); end if;",
            f"               Check (Test (Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) = Extract (R_B, Lane)) and then Test (Less_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) < Extract (R_B, Lane)) and then Test (Less_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) <= Extract (R_B, Lane)) and then Test (Greater_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) > Extract (R_B, Lane)) and then Test (Greater_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) >= Extract (R_B, Lane)), \"{vector} randomized independent comparison\" & Lane'Image);",
            f"               Check (Extract (Min_Number (R_A, R_B), Lane) = (if Extract (R_A, Lane) <= Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)) and then Extract (Max_Number (R_A, R_B), Lane) = (if Extract (R_A, Lane) >= Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)), \"{vector} randomized independent min/max\" & Lane'Image);",
            "            end loop;",
            "         end;",
            "      end loop;",
            f"   end Test_{vector};", "",
        ]
    lines += [
        "   function To_F32 is new Ada.Unchecked_Conversion (Interfaces.Unsigned_32, F32);",
        "   function F32_Bits is new Ada.Unchecked_Conversion (F32, Interfaces.Unsigned_32);",
        "   function To_F64 is new Ada.Unchecked_Conversion (Interfaces.Unsigned_64, F64);",
        "   function F64_Bits is new Ada.Unchecked_Conversion (F64, Interfaces.Unsigned_64);",
        "   function Is_NaN (Value : F32) return Boolean is",
        "     ((F32_Bits (Value) and 16#7F80_0000#) = 16#7F80_0000#",
        "      and then (F32_Bits (Value) and 16#007F_FFFF#) /= 0);",
        "   function Is_NaN (Value : F64) return Boolean is",
        "     ((F64_Bits (Value) and 16#7FF0_0000_0000_0000#) = 16#7FF0_0000_0000_0000#",
        "      and then (F64_Bits (Value) and 16#000F_FFFF_FFFF_FFFF#) /= 0);",
        "   function Is_Quiet_NaN (Value : F32) return Boolean is",
        "     (Is_NaN (Value) and then (F32_Bits (Value) and 16#0040_0000#) /= 0);",
        "   function Is_Quiet_NaN (Value : F64) return Boolean is",
        "     (Is_NaN (Value) and then (F64_Bits (Value) and 16#0008_0000_0000_0000#) /= 0);",
        "   procedure Test_Floating_Specials is",
        "      pragma Suppress (Validity_Check);",
        "      NaN32 : constant F32 := To_F32 (16#7FC0_0001#);",
        "      SNaN32 : constant F32 := To_F32 (16#7F80_0001#);",
        "      Inf32 : constant F32 := To_F32 (16#7F80_0000#);",
        "      Neg_Zero32 : constant F32 := To_F32 (16#8000_0000#);",
        "      A32 : constant F32x4 := From_Lanes ([NaN32, Inf32, Neg_Zero32, 0.0]);",
        "      B32 : constant F32x4 := From_Lanes ([1.0, Inf32, 0.0, Neg_Zero32]);",
        "      NaN64 : constant F64 := To_F64 (16#7FF8_0000_0000_0001#);",
        "      SNaN64 : constant F64 := To_F64 (16#7FF0_0000_0000_0001#);",
        "      Inf64 : constant F64 := To_F64 (16#7FF0_0000_0000_0000#);",
        "      Neg_Zero64 : constant F64 := To_F64 (16#8000_0000_0000_0000#);",
        "      A64 : constant F64x2 := From_Lanes ([NaN64, Neg_Zero64]);",
        "      B64 : constant F64x2 := From_Lanes ([1.0, 0.0]);",
        "      Zero32 : constant F32x4 := From_Lanes ([0.0, 0.0, 0.0, 0.0]);",
        "      Numerator32 : constant F32x4 := From_Lanes ([1.0, 0.0, -1.0, 0.0]);",
        "      Quiet32 : constant F32x4 := From_Lanes ([NaN32, NaN32, NaN32, NaN32]);",
        "      Signal32 : constant F32x4 := From_Lanes ([SNaN32, SNaN32, SNaN32, SNaN32]);",
        "      Number32 : constant F32x4 := From_Lanes ([1.0, 1.0, 1.0, 1.0]);",
        "      Zero64 : constant F64x2 := From_Lanes ([0.0, 0.0]);",
        "      Numerator64 : constant F64x2 := From_Lanes ([1.0, 0.0]);",
        "      Infinity64 : constant F64x2 := From_Lanes ([Inf64, 0.0]);",
        "      Twice64 : constant F64x2 := From_Lanes ([2.0, 0.0]);",
        "      Quiet64 : constant F64x2 := From_Lanes ([NaN64, NaN64]);",
        "      Signal64 : constant F64x2 := From_Lanes ([SNaN64, SNaN64]);",
        "      Number64 : constant F64x2 := From_Lanes ([1.0, 1.0]);",
        "   begin",
        "      Check (Backends.Native.To_Bit_Mask (Backends.Native.Unordered (A32, B32)) = Flyology_SIMD.To_Bit_Mask (Unordered (A32, B32)), \"F32 NaN unordered\");",
        "      Check (Extract (Backends.Native.Min_Number (A32, B32), 0) = 1.0 and then Extract (Backends.Native.Max_Number (A32, B32), 0) = 1.0, \"F32 quiet NaN returns number\");",
        "      Check ((F32_Bits (Extract (Backends.Native.Min_Number (From_Lanes ([SNaN32, 0.0, 0.0, 0.0]), B32), 0)) and 16#7FC0_0000#) = 16#7FC0_0000#, \"F32 signaling NaN is quieted\");",
        "      Check (F32_Bits (Extract (Backends.Native.Min_Number (A32, B32), 2)) = 16#8000_0000# and then F32_Bits (Extract (Backends.Native.Max_Number (A32, B32), 2)) = 0, \"F32 signed zero min/max\");",
        "      Check (Extract (Min_Number (Quiet32, Number32), 0) = 1.0 and then Extract (Max_Number (Quiet32, Number32), 0) = 1.0 and then Extract (Min_Number (Number32, Quiet32), 0) = 1.0 and then Extract (Max_Number (Number32, Quiet32), 0) = 1.0 and then Extract (Backends.Native.Min_Number (Quiet32, Number32), 0) = 1.0 and then Extract (Backends.Native.Max_Number (Quiet32, Number32), 0) = 1.0 and then Extract (Backends.Native.Min_Number (Number32, Quiet32), 0) = 1.0 and then Extract (Backends.Native.Max_Number (Number32, Quiet32), 0) = 1.0, \"F32 quiet NaN operand orders\");",
        "      Check (Is_Quiet_NaN (Extract (Min_Number (Signal32, Number32), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Signal32, Number32), 0)) and then Is_Quiet_NaN (Extract (Min_Number (Number32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Number32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Signal32, Number32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Signal32, Number32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Number32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Number32, Signal32), 0)), \"F32 signaling NaN operand orders\");",
        "      Check (Is_Quiet_NaN (Extract (Min_Number (Quiet32, Quiet32), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Quiet32, Quiet32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Quiet32, Quiet32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Quiet32, Quiet32), 0)), \"F32 two NaNs\");",
        "      Check (Is_NaN (Extract (Add (A32, B32), 0)) and then Is_NaN (Extract (Backends.Native.Add (A32, B32), 0)), \"F32 NaN addition\");",
        "      Check (Is_NaN (Extract (Subtract (A32, B32), 1)) and then Is_NaN (Extract (Backends.Native.Subtract (A32, B32), 1)), \"F32 infinity subtraction\");",
        "      Check (F32_Bits (Extract (Multiply (A32, B32), 1)) = 16#7F80_0000# and then F32_Bits (Extract (Backends.Native.Multiply (A32, B32), 1)) = 16#7F80_0000#, \"F32 infinity multiplication\");",
        "      Check (F32_Bits (Extract (Divide (Numerator32, Zero32), 0)) = 16#7F80_0000# and then F32_Bits (Extract (Backends.Native.Divide (Numerator32, Zero32), 0)) = 16#7F80_0000# and then Is_NaN (Extract (Divide (Numerator32, Zero32), 1)) and then Is_NaN (Extract (Backends.Native.Divide (Numerator32, Zero32), 1)), \"F32 division edge cases\");",
        "      Check (Is_NaN (Reduce_Add (A32)) and then Is_NaN (Backends.Native.Reduce_Add (A32)), \"F32 NaN reduction\");",
        "      Check (Backends.Native.To_Bit_Mask (Backends.Native.Unordered (A64, B64)) = Flyology_SIMD.To_Bit_Mask (Unordered (A64, B64)), \"F64 NaN unordered\");",
        "      Check (Extract (Backends.Native.Min_Number (A64, B64), 0) = 1.0 and then Extract (Backends.Native.Max_Number (A64, B64), 0) = 1.0, \"F64 quiet NaN returns number\");",
        "      Check ((F64_Bits (Extract (Backends.Native.Max_Number (From_Lanes ([SNaN64, 0.0]), B64), 0)) and 16#7FF8_0000_0000_0000#) = 16#7FF8_0000_0000_0000#, \"F64 signaling NaN is quieted\");",
        "      Check (F64_Bits (Extract (Backends.Native.Min_Number (A64, B64), 1)) = 16#8000_0000_0000_0000# and then F64_Bits (Extract (Backends.Native.Max_Number (A64, B64), 1)) = 0, \"F64 signed zero min/max\");",
        "      Check (Extract (Min_Number (Quiet64, Number64), 0) = 1.0 and then Extract (Max_Number (Quiet64, Number64), 0) = 1.0 and then Extract (Min_Number (Number64, Quiet64), 0) = 1.0 and then Extract (Max_Number (Number64, Quiet64), 0) = 1.0 and then Extract (Backends.Native.Min_Number (Quiet64, Number64), 0) = 1.0 and then Extract (Backends.Native.Max_Number (Quiet64, Number64), 0) = 1.0 and then Extract (Backends.Native.Min_Number (Number64, Quiet64), 0) = 1.0 and then Extract (Backends.Native.Max_Number (Number64, Quiet64), 0) = 1.0, \"F64 quiet NaN operand orders\");",
        "      Check (Is_Quiet_NaN (Extract (Min_Number (Signal64, Number64), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Signal64, Number64), 0)) and then Is_Quiet_NaN (Extract (Min_Number (Number64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Number64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Signal64, Number64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Signal64, Number64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Number64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Number64, Signal64), 0)), \"F64 signaling NaN operand orders\");",
        "      Check (Is_Quiet_NaN (Extract (Min_Number (Quiet64, Quiet64), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Quiet64, Quiet64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Quiet64, Quiet64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Quiet64, Quiet64), 0)), \"F64 two NaNs\");",
        "      Check (Is_NaN (Extract (Add (A64, B64), 0)) and then Is_NaN (Extract (Backends.Native.Add (A64, B64), 0)), \"F64 NaN addition\");",
        "      Check (Is_NaN (Extract (Subtract (Infinity64, Infinity64), 0)) and then Is_NaN (Extract (Backends.Native.Subtract (Infinity64, Infinity64), 0)), \"F64 infinity subtraction\");",
        "      Check (F64_Bits (Extract (Multiply (Infinity64, Twice64), 0)) = 16#7FF0_0000_0000_0000# and then F64_Bits (Extract (Backends.Native.Multiply (Infinity64, Twice64), 0)) = 16#7FF0_0000_0000_0000#, \"F64 infinity multiplication\");",
        "      Check (F64_Bits (Extract (Divide (Numerator64, Zero64), 0)) = 16#7FF0_0000_0000_0000# and then F64_Bits (Extract (Backends.Native.Divide (Numerator64, Zero64), 0)) = 16#7FF0_0000_0000_0000# and then Is_NaN (Extract (Divide (Numerator64, Zero64), 1)) and then Is_NaN (Extract (Backends.Native.Divide (Numerator64, Zero64), 1)), \"F64 division edge cases\");",
        "      Check (Is_NaN (Reduce_Add (A64)) and then Is_NaN (Backends.Native.Reduce_Add (A64)), \"F64 NaN reduction\");",
        "   end Test_Floating_Specials;", "",
        "begin", "   Put_Line (\"full-family differential tests seed=0x5EED0123D15CA11A\");",
    ]
    for vector, *_ in INTEGER_TYPES + FLOAT_TYPES:
        lines.append(f"   Test_{vector};")
    lines.append("   Test_Floating_Specials;")
    lines += [
        "   if Failures = 0 then Put_Line (\"PASS\"); else Put_Line (\"FAILURES:\" & Failures'Image); Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure); end if;",
        "exception when Error : others => Put_Line (\"UNCAUGHT: \" & Ada.Exceptions.Exception_Information (Error)); Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);",
        "end Family_Tests;", "",
    ]
    return "\n".join(lines)


def main() -> None:
    text = strip_generated_docs(SPEC.read_text())
    SPEC.write_text(document_spec(replace_block(text, "GENERATED FULL-FAMILY BACKEND CONTRACT", contract())))
    SCALAR_SPEC.write_text(document_spec(strip_generated_docs(SCALAR_SPEC.read_text())))
    text = NEON.read_text()
    NEON.write_text(replace_block(text, "GENERATED FULL-FAMILY NEON BODIES", neon_body()))
    text = X86.read_text().replace(
        "GENERATED FULL-FAMILY FALLBACK BODIES",
        "GENERATED FULL-FAMILY X86 BODIES",
    )
    X86.write_text(replace_block(text, "GENERATED FULL-FAMILY X86 BODIES", x86_body()))
    generated = fallback_body()
    for path in FALLBACKS:
        text = path.read_text()
        path.write_text(replace_block(text, "GENERATED FULL-FAMILY FALLBACK BODIES", generated))
    TEST.write_text(test_program())


if __name__ == "__main__":
    main()
