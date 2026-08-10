#!/usr/bin/env python3
"""Generate the full 128-bit backend contract and implementations."""

from pathlib import Path

from generate_full_family import (
    FLOAT_TYPES,
    INTEGER_TYPES,
    MASKS,
    ROOT,
    array_name,
    emit_spec,
    lane_count,
    lane_index,
    lane_values,
    mask_for,
    replace_block,
)

SPEC = ROOT / "src" / "flyology_simd-backends-native.ads"
NEON = ROOT / "src" / "backends" / "aarch64" / "flyology_simd-backends-native.adb"
FALLBACKS = [
    ROOT / "src" / "backends" / "scalar" / "flyology_simd-backends-native.adb",
    ROOT / "src" / "backends" / "x86_64" / "flyology_simd-backends-native.adb",
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
                     "Interleave_Low", "Interleave_High"):
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
        for name, op in (("Add", "fadd"), ("Subtract", "fsub"), ("Multiply", "fmul"), ("Divide", "fdiv"), ("Min_Number", "fminnm"), ("Max_Number", "fmaxnm"), ("Interleave_Low", "zip1"), ("Interleave_High", "zip2")):
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
        out += [call("Mask_From_Bit_Mask", mask, "Bits", f"Bits : {st}"), call("To_Bit_Mask", st, "Mask", f"Mask : {mask}"), call("Test", "Boolean", "Mask, Lane", f"Mask : {mask}; Lane : {idx}"), call("Any_True", "Boolean", "Mask", f"Mask : {mask}"), call("All_True", "Boolean", "Mask", f"Mask : {mask}"), call("None_True", "Boolean", "Mask", f"Mask : {mask}"), call("Population_Count", count, "Mask", f"Mask : {mask}")]
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
        "   Failures : Natural := 0;", "   procedure Check (Condition : Boolean; Message : String) is",
        "   begin if not Condition then Failures := Failures + 1; Put_Line (\"FAIL: \" & Message); end if; end Check;", "",
    ]
    for vector, scalar, bits, lanes, signed in INTEGER_TYPES:
        vals, arr, count = lane_values(vector), array_name(scalar), lane_count(bits, lanes)
        mask_storage = "Interfaces.Unsigned_16" if lanes == 16 else "Interfaces.Unsigned_8"
        if signed:
            av = [f"{scalar}'First", "-1", "0", "1", f"{scalar}'Last"]
            bv = ["1", f"{scalar}'Last", "-1", f"{scalar}'First", "0"]
        else:
            av = ["0", "1", f"{scalar}'Last", f"2 ** ({bits - 1})", "17"]
            bv = ["1", f"{scalar}'Last", "2", f"2 ** ({bits - 1}) - 1", "9"]
        agg_a = ", ".join(av[n % len(av)] for n in range(lanes))
        agg_b = ", ".join(bv[n % len(bv)] for n in range(lanes))
        lines += [
            f"   function Same (Left, Right : {vector}) return Boolean is (To_Lanes (Left) = To_Lanes (Right));",
            f"   procedure Test_{vector} is",
            f"      A : constant {vector} := From_Lanes ([{agg_a}]);",
            f"      B : constant {vector} := From_Lanes ([{agg_b}]);",
            f"      Data, Reference : {arr} (0 .. {lanes + 5}) := [others => 0];",
            "   begin",
        ]
        for name in ("Add_Wrap", "Subtract_Wrap", "Multiply_Wrap", "Add_Saturate", "Subtract_Saturate", "Bitwise_And", "Bitwise_Or", "Bitwise_Xor", "Min", "Max", "Interleave_Low", "Interleave_High"):
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
        lines += ["      end loop;"]
        for name in ("Equal", "Less_Than", "Less_Equal", "Greater_Than", "Greater_Equal"):
            lines.append(f"      Check (Backends.Native.To_Bit_Mask (Backends.Native.{name} (A, B)) = Flyology_SIMD.To_Bit_Mask ({name} (A, B)), \"{vector} {name}\");")
        lines += [
            f"      Check (Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), \"{vector} select\");",
            f"      Check (Backends.Native.Reduce_Add_Wrap (A) = Reduce_Add_Wrap (A), \"{vector} reduce add\");",
            f"      Check (Backends.Native.Reduce_Min (A) = Reduce_Min (A), \"{vector} reduce min\");",
            f"      Check (Backends.Native.Reduce_Max (A) = Reduce_Max (A), \"{vector} reduce max\");",
            f"      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);",
            f"      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), \"{vector} full memory\");",
            f"      for N in {count} loop",
            "         Data := [others => 0]; Reference := [others => 0];",
            f"         Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B);",
            f"         Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, N), Load_Partial (Data, 2, N)), \"{vector} partial\" & N'Image);",
            "      end loop;",
            "      for Iteration in 1 .. 250 loop",
            "         declare",
            f"            R_A : constant {vector} := From_Lanes ([for Lane in {lane_index(bits, lanes)} => {scalar} ({'((Iteration * 37 + Lane * 19) mod 251) - 125' if signed else '(Iteration * 37 + Lane * 19) mod 251'})]);",
            f"            R_B : constant {vector} := From_Lanes ([for Lane in {lane_index(bits, lanes)} => {scalar} ({'((Iteration * 23 + Lane * 29) mod 251) - 125' if signed else '(Iteration * 23 + Lane * 29) mod 251'})]);",
            "         begin",
            f"            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), \"{vector} randomized arithmetic\");",
            f"            Check (Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)), \"{vector} randomized compare\");",
            "         end;",
            "      end loop;",
            f"   end Test_{vector};", "",
        ]
    for vector, scalar, bits, lanes in FLOAT_TYPES:
        vals, arr, count = lane_values(vector), array_name(scalar), lane_count(bits, lanes)
        av = ["0.0", "-0.0", "1.5", "-2.25", "17.0"]
        bv = ["2.0", "-3.0", "0.5", "4.0", "-1.0"]
        agg_a = ", ".join(av[n % len(av)] for n in range(lanes))
        agg_b = ", ".join(bv[n % len(bv)] for n in range(lanes))
        lines += [
            f"   function Same (Left, Right : {vector}) return Boolean is (To_Lanes (Left) = To_Lanes (Right));",
            f"   procedure Test_{vector} is",
            f"      A : constant {vector} := From_Lanes ([{agg_a}]);", f"      B : constant {vector} := From_Lanes ([{agg_b}]);",
            f"      Data, Reference : {arr} (0 .. {lanes + 5}) := [others => 0.0];", "   begin",
        ]
        for name in ("Add", "Subtract", "Multiply", "Divide", "Min_Number", "Max_Number", "Interleave_Low", "Interleave_High"):
            lines.append(f"      Check (Same (Backends.Native.{name} (A, B), {name} (A, B)), \"{vector} {name}\");")
        lines += [f"      Check (Same (Backends.Native.Reverse_Lanes (A), Reverse_Lanes (A)), \"{vector} reverse\");"]
        for name in ("Equal", "Less_Than", "Less_Equal", "Greater_Than", "Greater_Equal", "Unordered"):
            lines.append(f"      Check (Backends.Native.To_Bit_Mask (Backends.Native.{name} (A, B)) = Flyology_SIMD.To_Bit_Mask ({name} (A, B)), \"{vector} {name}\");")
        lines += [
            f"      Check (Same (Backends.Native.Select_Value (Equal (A, B), A, B), Select_Value (Equal (A, B), A, B)), \"{vector} select\");",
            f"      Check (Backends.Native.Reduce_Add (A) = Reduce_Add (A), \"{vector} reduce\");",
            f"      Backends.Native.Store_Unaligned (Data, 1, A); Store_Unaligned (Reference, 1, A);",
            f"      Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), Load_Unaligned (Data, 1)), \"{vector} full memory\");",
            f"      for N in {count} loop Data := [others => 0.0]; Reference := [others => 0.0]; Backends.Native.Store_Partial (Data, 2, N, B); Store_Partial (Reference, 2, N, B); Check (Data = Reference and then Same (Backends.Native.Load_Partial (Data, 2, N), Load_Partial (Data, 2, N)), \"{vector} partial\" & N'Image); end loop;",
            "      for Iteration in 1 .. 250 loop",
            "         declare",
            f"            R_A : constant {vector} := From_Lanes ([for Lane in {lane_index(bits, lanes)} => {scalar} (Iteration * 37 + Lane * 19) / 7.0]);",
            f"            R_B : constant {vector} := From_Lanes ([for Lane in {lane_index(bits, lanes)} => {scalar} (Iteration * 23 + Lane * 29 + 1) / 11.0]);",
            "         begin",
            f"            Check (Same (Backends.Native.Multiply (R_A, R_B), Multiply (R_A, R_B)) and then Same (Backends.Native.Divide (R_A, R_B), Divide (R_A, R_B)), \"{vector} randomized arithmetic\");",
            f"            Check (Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (R_A, R_B)), \"{vector} randomized compare\");",
            "         end;",
            "      end loop;",
            f"   end Test_{vector};", "",
        ]
    lines += [
        "   function To_F32 is new Ada.Unchecked_Conversion (Interfaces.Unsigned_32, F32);",
        "   function F32_Bits is new Ada.Unchecked_Conversion (F32, Interfaces.Unsigned_32);",
        "   function To_F64 is new Ada.Unchecked_Conversion (Interfaces.Unsigned_64, F64);",
        "   function F64_Bits is new Ada.Unchecked_Conversion (F64, Interfaces.Unsigned_64);",
        "   procedure Test_Floating_Specials is",
        "      pragma Suppress (Validity_Check);",
        "      NaN32 : constant F32 := To_F32 (16#7FC0_0001#);",
        "      Inf32 : constant F32 := To_F32 (16#7F80_0000#);",
        "      Neg_Zero32 : constant F32 := To_F32 (16#8000_0000#);",
        "      A32 : constant F32x4 := From_Lanes ([NaN32, Inf32, Neg_Zero32, 0.0]);",
        "      B32 : constant F32x4 := From_Lanes ([1.0, Inf32, 0.0, Neg_Zero32]);",
        "      NaN64 : constant F64 := To_F64 (16#7FF8_0000_0000_0001#);",
        "      Neg_Zero64 : constant F64 := To_F64 (16#8000_0000_0000_0000#);",
        "      A64 : constant F64x2 := From_Lanes ([NaN64, Neg_Zero64]);",
        "      B64 : constant F64x2 := From_Lanes ([1.0, 0.0]);",
        "   begin",
        "      Check (Backends.Native.To_Bit_Mask (Backends.Native.Unordered (A32, B32)) = Flyology_SIMD.To_Bit_Mask (Unordered (A32, B32)), \"F32 NaN unordered\");",
        "      Check (F32_Bits (Extract (Backends.Native.Min_Number (A32, B32), 2)) = 16#8000_0000# and then F32_Bits (Extract (Backends.Native.Max_Number (A32, B32), 2)) = 0, \"F32 signed zero min/max\");",
        "      Check (Backends.Native.To_Bit_Mask (Backends.Native.Unordered (A64, B64)) = Flyology_SIMD.To_Bit_Mask (Unordered (A64, B64)), \"F64 NaN unordered\");",
        "      Check (F64_Bits (Extract (Backends.Native.Min_Number (A64, B64), 1)) = 16#8000_0000_0000_0000# and then F64_Bits (Extract (Backends.Native.Max_Number (A64, B64), 1)) = 0, \"F64 signed zero min/max\");",
        "   end Test_Floating_Specials;", "",
        "begin", "   Put_Line (\"full-family differential tests seed=0x5EED0123\");",
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
    text = SPEC.read_text()
    SPEC.write_text(replace_block(text, "GENERATED FULL-FAMILY BACKEND CONTRACT", contract()))
    text = NEON.read_text()
    NEON.write_text(replace_block(text, "GENERATED FULL-FAMILY NEON BODIES", neon_body()))
    generated = fallback_body()
    for path in FALLBACKS:
        text = path.read_text()
        path.write_text(replace_block(text, "GENERATED FULL-FAMILY FALLBACK BODIES", generated))
    TEST.write_text(test_program())


if __name__ == "__main__":
    main()
