#!/usr/bin/env python3
"""Generate the full 128-bit backend contract and implementations."""

from pathlib import Path
import re

from generate_full_family import (
    FLOAT_TO_INTEGER_CONVERSIONS,
    BIT_CAST_GROUPS,
    FLOAT_TYPES,
    FLOAT_NARROWINGS,
    FLOAT_WIDENINGS,
    INTEGER_TO_FLOAT_CONVERSIONS,
    INTEGER_TYPES,
    MASKS,
    NARROWINGS,
    ROOT,
    SIGNED_UNSIGNED_CONVERSIONS,
    SIGNED_TO_UNSIGNED_NARROWINGS,
    WIDENINGS,
    array_name,
    bit_cast_pairs,
    document_spec,
    emit_conversion_spec,
    emit_spec,
    lane_count,
    lane_index,
    lane_map,
    lane_selectors,
    lane_values,
    mask_for,
    replace_block,
    strip_generated_docs,
    two_source_lane_map,
    two_source_lane_selectors,
)

SPEC = ROOT / "src" / "flyology_simd-backends-native.ads"
SCALAR_SPEC = ROOT / "src" / "flyology_simd-backends-scalar.ads"
NEON = ROOT / "src" / "backends" / "aarch64" / "flyology_simd-backends-native.adb"
X86 = ROOT / "src" / "backends" / "x86_64" / "flyology_simd-backends-native.adb"
FALLBACKS = [
    ROOT / "src" / "backends" / "scalar" / "flyology_simd-backends-native.adb",
]
TEST = ROOT / "tests" / "family_tests.adb"


def value_types() -> list[tuple[str, str, int, int]]:
    return [("U8x16", "U8", 8, 16)] + [
        (vector, scalar, bits, lanes)
        for vector, scalar, bits, lanes, *_ in INTEGER_TYPES
    ] + list(FLOAT_TYPES)


def contract() -> str:
    generated = emit_spec()
    operations = "   function Zero return I8x16;" + generated.split(
        "   function Zero return I8x16;", 1
    )[1]
    byte_operations = "\n".join(
        [
            "   function Table_Lookup (Table, Indices : U8x16) return U8x16;",
            "   function Permute_Lanes (Value : U8x16; Map : Lane_Map_8x16) return U8x16;",
            "   function Permute_Lanes (Left, Right : U8x16; Map : Two_Source_Lane_Map_8x16) return U8x16;",
            "   function Compress (Value : U8x16; Mask : Mask_8x16) return U8x16;",
            "   function Expand (Value : U8x16; Mask : Mask_8x16) return U8x16;",
            "   function Slide_Lanes_Toward_Low (Value : U8x16; Count : Natural) return U8x16;",
            "   function Slide_Lanes_Toward_High (Value : U8x16; Count : Natural) return U8x16;",
        ]
    )
    result = emit_conversion_spec() + "\n" + byte_operations + "\n" + operations
    return strip_generated_docs(re.sub(
        r"(function (?:Slide_Lanes_Toward_(?:Low|High) "
        r"\(Value : [A-Za-z0-9_]+; Count : Natural\) return [A-Za-z0-9_]+|"
        r"(?:Compress|Expand) \(Value : [A-Za-z0-9_]+; Mask : Mask_[A-Za-z0-9_]+\) return [A-Za-z0-9_]+|"
        r"Permute_Lanes \(Value : [A-Za-z0-9_]+; Map : Lane_Map_[A-Za-z0-9_]+\) return [A-Za-z0-9_]+|"
        r"Permute_Lanes \(Left, Right : [A-Za-z0-9_]+; Map : Two_Source_Lane_Map_[A-Za-z0-9_]+\) return [A-Za-z0-9_]+));",
        r"\1 with Inline_Always;",
        result,
    ))


def scalar_contract(native_spec: str) -> str:
    """Generate a scalar package with the exact Native subprogram surface."""
    body_start = native_spec.index("\nis\n") + len("\nis\n")
    body_end = native_spec.rindex("\nend Flyology_SIMD.Backends.Native;")
    lines = native_spec[body_start:body_end].splitlines()
    declarations: list[str] = []
    index = 0
    while index < len(lines):
        if not re.match(r"   (function|procedure)\s+", lines[index]):
            index += 1
            continue
        declaration = [lines[index]]
        depth = 0
        complete = False
        while not complete:
            for character in declaration[-1]:
                if character == "(":
                    depth += 1
                elif character == ")":
                    depth -= 1
                elif character == ";" and depth == 0:
                    complete = True
                    break
            if complete:
                break
            index += 1
            declaration.append(lines[index])
        text = "\n".join(declaration)
        text = re.sub(
            r"\s+with\s+(?:Pre|Post)\s*=>.*?;\s*$|"
            r"\s+with\s+Inline_Always\s*;\s*$",
            ";",
            text,
            flags=re.S,
        )
        match = re.match(r"   (?:function|procedure)\s+([A-Za-z0-9_]+)", text)
        assert match is not None
        name = match.group(1)
        declarations.append(
            text.rstrip()[:-1]
            + f"\n     renames Flyology_SIMD.{name};"
        )
        index += 1

    return document_spec(
        "with Interfaces;\n\n"
        "--  Authoritative scalar implementation of the complete primitive "
        "operation contract.\n"
        "package Flyology_SIMD.Backends.Scalar\n"
        "  with Preelaborate\n"
        "is\n"
        + "\n".join(declarations)
        + "\nend Flyology_SIMD.Backends.Scalar;\n",
        support="scalar",
    )


def call(name: str, result: str, args: str, params: str) -> str:
    return (
        f"   function {name} ({params}) return {result} is\n"
        f"     (Flyology_SIMD.{name} ({args}));"
    )


def native_mask_body(bits: int, lanes: int, storage: str) -> list[str]:
    """Implement compact masks directly without crossing the root API."""
    mask = mask_for(bits, lanes)
    idx = lane_index(bits, lanes)
    st = f"Interfaces.{storage}"
    full = 2 ** lanes - 1
    return [
        f"   function Mask_From_Bit_Mask (Bits : {st}) return {mask} is",
        f"     (Bits => Bits and {full});",
        f"   function To_Bit_Mask (Mask : {mask}) return {st} is",
        f"     (Mask.Bits and {full});",
        f"   function Mask_And (Left, Right : {mask}) return {mask} is",
        f"     (Bits => (Left.Bits and Right.Bits) and {full});",
        f"   function Mask_Or (Left, Right : {mask}) return {mask} is",
        f"     (Bits => (Left.Bits or Right.Bits) and {full});",
        f"   function Mask_Xor (Left, Right : {mask}) return {mask} is",
        f"     (Bits => (Left.Bits xor Right.Bits) and {full});",
        f"   function Mask_Not (Value : {mask}) return {mask} is",
        f"     (Bits => (not Value.Bits) and {full});",
        f"   function Test (Mask : {mask}; Lane : {idx}) return Boolean is",
        f"     ((Mask.Bits and Interfaces.Shift_Left ({st}'(1), Lane)) /= 0);",
        f"   function Any_True (Mask : {mask}) return Boolean is",
        "     (Mask.Bits /= 0);",
        f"   function All_True (Mask : {mask}) return Boolean is",
        f"     ((Mask.Bits and {full}) = {full});",
        f"   function None_True (Mask : {mask}) return Boolean is",
        "     (Mask.Bits = 0);",
    ]


def direct_construction_body(vector: str, scalar: str) -> list[str]:
    """Construct private target values without crossing the root API."""
    zero = "0.0" if scalar in {"F32", "F64"} else "0"
    return [
        f"   function Zero return {vector} is (Lanes => [others => {zero}]);",
        f"   function Splat (Value : {scalar}) return {vector} is",
        "     (Lanes => [others => Value]);",
    ]


def direct_lane_access_body(
    vector: str, scalar: str, values: str, index: str
) -> list[str]:
    """Access private lanes directly without crossing the root API."""
    return [
        f"   function From_Lanes (Values : {values}) return {vector} is",
        "     (Lanes => Values);",
        f"   function To_Lanes (Value : {vector}) return {values} is",
        "     (Value.Lanes);",
        f"   function Extract (Value : {vector}; Lane : {index}) return {scalar} is",
        "     (Value.Lanes (Lane));",
        f"   function Replace (Value : {vector}; Lane : {index}; With_Value : {scalar}) return {vector} is",
        f"      Result : {vector} := Value;",
        "   begin",
        "      Result.Lanes (Lane) := With_Value;",
        "      return Result;",
        "   end Replace;",
    ]


def direct_partial_memory_body(
    vector: str, array: str, count: str, index: str, zero: str
) -> list[str]:
    """Read and write only active lanes without crossing the root API."""
    return [
        f"   function Load_Partial (Data : {array}; Start : Natural; Count : {count}) return {vector} is",
        f"      Result : {vector} := (Lanes => [others => {zero}]);",
        "   begin",
        "      if Count > 0 then",
        "         for Lane in Natural range 0 .. Count - 1 loop",
        f"            Result.Lanes ({index} (Lane)) := Data (Start + Lane);",
        "         end loop;",
        "      end if;",
        "      return Result;",
        "   end Load_Partial;",
        f"   procedure Store_Partial (Data : in out {array}; Start : Natural; Count : {count}; Value : {vector}) is",
        "   begin",
        "      if Count > 0 then",
        "         for Lane in Natural range 0 .. Count - 1 loop",
        f"            Data (Start + Lane) := Value.Lanes ({index} (Lane));",
        "         end loop;",
        "      end if;",
        "   end Store_Partial;",
    ]


def target_construction_body(
    architecture: str, vector: str, scalar: str, bits: int, lanes: int
) -> list[str]:
    """Instantiate exact target zero and bit-preserving splat leaves."""
    zero = f"Native_Zero_{vector}"
    splat = f"Native_Splat_{vector}"
    if architecture == "aarch64":
        element = {8: "b", 16: "h", 32: "s", 64: "d"}[bits]
        load = f"ldr {element}0, [%1]"
        duplicate = f"dup v0.{lanes}{element}, v0.{element}[0]"
        helper_zero = "NEON_Zero_128"
        helper_splat = "NEON_Splat_128"
        instructions = f'"{load}", "{duplicate}"'
    else:
        if bits == 8:
            load = "movzbl (%1), %%eax"
            duplicate = (
                "imull $0x01010101, %%eax, %%eax\n"
                "movd %%eax, %%xmm0\n"
                "pshufd $0, %%xmm0, %%xmm0"
            )
        elif bits == 16:
            load = "movzwl (%1), %%eax"
            duplicate = (
                "imull $0x00010001, %%eax, %%eax\n"
                "movd %%eax, %%xmm0\n"
                "pshufd $0, %%xmm0, %%xmm0"
            )
        elif bits == 32:
            load = "movl (%1), %%eax"
            duplicate = "movd %%eax, %%xmm0\npshufd $0, %%xmm0, %%xmm0"
        else:
            load = "movq (%1), %%rax"
            duplicate = "movq %%rax, %%xmm0\npunpcklqdq %%xmm0, %%xmm0"
        helper_zero = "SSE2_Zero_128"
        helper_splat = "SSE2_Splat_128"
        instructions = (
            f'"{x86_ada_instruction(load)}", '
            f'"{x86_ada_instruction(duplicate)}"'
        )
    return [
        f"   function {zero} is new {helper_zero} ({vector});",
        f"   function Zero return {vector} is ({zero});",
        f"   function {splat} is new {helper_splat} ({vector}, {scalar}, {instructions});",
        f"   function Splat (Value : {scalar}) return {vector} is ({splat} (Value));",
    ]


def fallback_body() -> str:
    out: list[str] = [
        call("Table_Lookup", "U8x16", "Table, Indices", "Table, Indices : U8x16"),
        call("Permute_Lanes", "U8x16", "Value, Map", "Value : U8x16; Map : Lane_Map_8x16"),
        call("Permute_Lanes", "U8x16", "Left, Right, Map", "Left, Right : U8x16; Map : Two_Source_Lane_Map_8x16"),
        call("Compress", "U8x16", "Value, Mask", "Value : U8x16; Mask : Mask_8x16"),
        call("Expand", "U8x16", "Value, Mask", "Value : U8x16; Mask : Mask_8x16"),
        call("Slide_Lanes_Toward_Low", "U8x16", "Value, Count", "Value : U8x16; Count : Natural"),
        call("Slide_Lanes_Toward_High", "U8x16", "Value, Count", "Value : U8x16; Count : Natural"),
    ]
    for source_vector, _, target_vector, _ in bit_cast_pairs():
        out.append(call("Bit_Cast", target_vector, "Value", f"Value : {source_vector}"))
    for source_vector, _, target_vector, _, _, _ in WIDENINGS:
        out += [
            call("Widen_Low", target_vector, "Value", f"Value : {source_vector}"),
            call("Widen_High", target_vector, "Value", f"Value : {source_vector}"),
        ]
    for source_vector, _, target_vector, _, _ in FLOAT_WIDENINGS:
        out += [
            call("Widen_Low", target_vector, "Value", f"Value : {source_vector}"),
            call("Widen_High", target_vector, "Value", f"Value : {source_vector}"),
        ]
    for source_vector, _, target_vector, _, _, _, _ in NARROWINGS:
        out += [
            call("Narrow_Truncate", target_vector, "Low, High", f"Low, High : {source_vector}"),
            call("Narrow_Saturate", target_vector, "Low, High", f"Low, High : {source_vector}"),
        ]
    for source_vector, _, target_vector, _, _, _, _ in SIGNED_TO_UNSIGNED_NARROWINGS:
        out.append(call("Narrow_Saturate", target_vector, "Low, High", f"Low, High : {source_vector}"))
    for source_vector, _, target_vector, _, _ in FLOAT_NARROWINGS:
        out.append(call("Narrow_Round", target_vector, "Low, High", f"Low, High : {source_vector}"))
    for source_vector, _, target_vector, _, _, _, _ in INTEGER_TO_FLOAT_CONVERSIONS:
        out.append(call("Convert_Round", target_vector, "Value", f"Value : {source_vector}"))
    for source_vector, _, target_vector, _, _, _, _ in FLOAT_TO_INTEGER_CONVERSIONS:
        out.append(
            call(
                "Convert_Truncate_Saturate",
                target_vector,
                "Value",
                f"Value : {source_vector}",
            )
        )
    for source_vector, _, target_vector, _, _, _, _ in SIGNED_UNSIGNED_CONVERSIONS:
        out.append(call("Convert_Saturate", target_vector, "Value", f"Value : {source_vector}"))
    for vector, scalar, bits, lanes, signed in INTEGER_TYPES:
        idx, vals, mask = lane_index(bits, lanes), lane_values(vector), mask_for(bits, lanes)
        arr, count = array_name(scalar), lane_count(bits, lanes)
        out += [
            *direct_construction_body(vector, scalar),
            call("From_Lanes", vector, "Values", f"Values : {vals}"),
            call("To_Lanes", vals, "Value", f"Value : {vector}"),
            call("Extract", scalar, "Value, Lane", f"Value : {vector}; Lane : {idx}"),
            call("Replace", vector, "Value, Lane, With_Value", f"Value : {vector}; Lane : {idx}; With_Value : {scalar}"),
            call("Permute_Lanes", vector, "Value, Map", f"Value : {vector}; Map : {lane_map(bits, lanes)}"),
            call("Permute_Lanes", vector, "Left, Right, Map", f"Left, Right : {vector}; Map : {two_source_lane_map(bits, lanes)}"),
            call("Compress", vector, "Value, Mask", f"Value : {vector}; Mask : {mask}"),
            call("Expand", vector, "Value, Mask", f"Value : {vector}; Mask : {mask}"),
        ]
        for name in ("Add_Wrap", "Subtract_Wrap", "Multiply_Wrap", "Add_Saturate", "Subtract_Saturate",
                     "Bitwise_And", "Bitwise_Or", "Bitwise_Xor", "Min", "Max",
                     "Interleave_Low", "Interleave_High", "Deinterleave_Even",
                     "Deinterleave_Odd"):
            out.append(call(name, vector, "Left, Right", f"Left, Right : {vector}"))
        out.append(call("Bitwise_Not", vector, "Value", f"Value : {vector}"))
        out += [
            call("Slide_Lanes_Toward_Low", vector, "Value, Count", f"Value : {vector}; Count : Natural"),
            call("Slide_Lanes_Toward_High", vector, "Value, Count", f"Value : {vector}; Count : Natural"),
        ]
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
            *direct_construction_body(vector, scalar),
            call("From_Lanes", vector, "Values", f"Values : {vals}"),
            call("To_Lanes", vals, "Value", f"Value : {vector}"),
            call("Extract", scalar, "Value, Lane", f"Value : {vector}; Lane : {idx}"),
            call("Replace", vector, "Value, Lane, With_Value", f"Value : {vector}; Lane : {idx}; With_Value : {scalar}"),
            call("Permute_Lanes", vector, "Value, Map", f"Value : {vector}; Map : {lane_map(bits, lanes)}"),
            call("Permute_Lanes", vector, "Left, Right, Map", f"Left, Right : {vector}; Map : {two_source_lane_map(bits, lanes)}"),
            call("Compress", vector, "Value, Mask", f"Value : {vector}; Mask : {mask}"),
            call("Expand", vector, "Value, Mask", f"Value : {vector}; Mask : {mask}"),
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
            call("Reduce_Min_Number", scalar, "Value", f"Value : {vector}"),
            call("Reduce_Max_Number", scalar, "Value", f"Value : {vector}"),
            call("Reverse_Lanes", vector, "Value", f"Value : {vector}"),
            call("Interleave_Low", vector, "Left, Right", f"Left, Right : {vector}"),
            call("Interleave_High", vector, "Left, Right", f"Left, Right : {vector}"),
            call("Deinterleave_Even", vector, "Left, Right", f"Left, Right : {vector}"),
            call("Deinterleave_Odd", vector, "Left, Right", f"Left, Right : {vector}"),
            call("Slide_Lanes_Toward_Low", vector, "Value, Count", f"Value : {vector}; Count : Natural"),
            call("Slide_Lanes_Toward_High", vector, "Value, Count", f"Value : {vector}; Count : Natural"),
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
            call("First_True", count, "Mask", f"Mask : {mask}"),
            call("Last_True", count, "Mask", f"Mask : {mask}"),
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
        "   function NEON_Multiply_64_128 (Left, Right : Vector_Type) return Vector_Type;",
        "   function NEON_Multiply_64_128 (Left, Right : Vector_Type) return Vector_Type is",
        "      Result : Vector_Type;",
        "   begin",
        "      Asm (Template => \"ldr q0, [%1]\" & ASCII.LF & ASCII.HT &",
        "           \"ldr q1, [%2]\" & ASCII.LF & ASCII.HT &",
        "           \"uzp1 v2.4s, v0.4s, v0.4s\" & ASCII.LF & ASCII.HT &",
        "           \"uzp2 v3.4s, v0.4s, v0.4s\" & ASCII.LF & ASCII.HT &",
        "           \"uzp1 v4.4s, v1.4s, v1.4s\" & ASCII.LF & ASCII.HT &",
        "           \"uzp2 v5.4s, v1.4s, v1.4s\" & ASCII.LF & ASCII.HT &",
        "           \"umull v6.2d, v2.2s, v4.2s\" & ASCII.LF & ASCII.HT &",
        "           \"mul v7.2s, v2.2s, v5.2s\" & ASCII.LF & ASCII.HT &",
        "           \"mla v7.2s, v3.2s, v4.2s\" & ASCII.LF & ASCII.HT &",
        "           \"shll v7.2d, v7.2s, #32\" & ASCII.LF & ASCII.HT &",
        "           \"add v0.2d, v6.2d, v7.2d\" & ASCII.LF & ASCII.HT &",
        "           \"str q0, [%0]\",",
        "           Inputs => [System.Address'Asm_Input (\"r\", Result'Address), System.Address'Asm_Input (\"r\", Left'Address), System.Address'Asm_Input (\"r\", Right'Address)],",
        "           Clobber => \"v0,v1,v2,v3,v4,v5,v6,v7,memory\", Volatile => True);",
        "      return Result;",
        "   end NEON_Multiply_64_128;",
        "",
        "   generic",
        "      type Vector_Type is private;",
        "      type Map_Type is private;",
        "   function NEON_Permute_128 (Value : Vector_Type; Map : Map_Type) return Vector_Type;",
        "   function NEON_Permute_128 (Value : Vector_Type; Map : Map_Type) return Vector_Type is",
        "      Result : Vector_Type;",
        "   begin",
        "      Asm (Template => \"ldr q0, [%1]\" & ASCII.LF & ASCII.HT &",
        "           \"ldr q1, [%2]\" & ASCII.LF & ASCII.HT &",
        "           \"tbl v0.16b, {v0.16b}, v1.16b\" & ASCII.LF & ASCII.HT &",
        "           \"str q0, [%0]\",",
        "           Inputs => [System.Address'Asm_Input (\"r\", Result'Address), System.Address'Asm_Input (\"r\", Value'Address), System.Address'Asm_Input (\"r\", Map'Address)],",
        "           Clobber => \"v0,v1,memory\", Volatile => True);",
        "      return Result;",
        "   end NEON_Permute_128;",
        "",
        "   generic",
        "      type Vector_Type is private;",
        "      type Map_Type is private;",
        "   function NEON_Permute_2_128 (Left, Right : Vector_Type; Map : Map_Type) return Vector_Type;",
        "   function NEON_Permute_2_128 (Left, Right : Vector_Type; Map : Map_Type) return Vector_Type is",
        "      Result : Vector_Type;",
        "   begin",
        '      Asm (Template => "ldr q0, [%1]" & ASCII.LF & ASCII.HT &',
        '           "ldr q1, [%2]" & ASCII.LF & ASCII.HT &',
        '           "ldr q2, [%3]" & ASCII.LF & ASCII.HT &',
        '           "tbl v0.16b, {v0.16b, v1.16b}, v2.16b" & ASCII.LF & ASCII.HT &',
        '           "str q0, [%0]",',
        '           Inputs => [System.Address\'Asm_Input ("r", Result\'Address), System.Address\'Asm_Input ("r", Left\'Address), System.Address\'Asm_Input ("r", Right\'Address), System.Address\'Asm_Input ("r", Map\'Address)],',
        '           Clobber => "v0,v1,v2,memory", Volatile => True);',
        "      return Result;",
        "   end NEON_Permute_2_128;",
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
        "           Clobber => \"v0,v1,memory\", Volatile => True);",
        "      return Result;",
        "   end NEON_Unary_128;",
        "",
        "   generic",
        "      type Vector_Type is private;",
        "   function NEON_Zero_128 return Vector_Type;",
        "   function NEON_Zero_128 return Vector_Type is",
        "      Result : Vector_Type;",
        "   begin",
        '      Asm (Template => "movi v0.16b, #0" & ASCII.LF & ASCII.HT & "str q0, [%0]",',
        '           Inputs => System.Address\'Asm_Input ("r", Result\'Address),',
        '           Clobber => "v0,memory", Volatile => True);',
        "      return Result;",
        "   end NEON_Zero_128;",
        "",
        "   generic",
        "      type Vector_Type is private;",
        "      type Scalar_Type is private;",
        "      Load_Instruction : String;",
        "      Duplicate_Instruction : String;",
        "   function NEON_Splat_128 (Value : Scalar_Type) return Vector_Type;",
        "   function NEON_Splat_128 (Value : Scalar_Type) return Vector_Type is",
        "      Result : Vector_Type;",
        "   begin",
        '      Asm (Template => Load_Instruction & ASCII.LF & ASCII.HT & Duplicate_Instruction & ASCII.LF & ASCII.HT & "str q0, [%0]",',
        '           Inputs => [System.Address\'Asm_Input ("r", Result\'Address), System.Address\'Asm_Input ("r", Value\'Address)],',
        '           Clobber => "v0,memory", Volatile => True);',
        "      return Result;",
        "   end NEON_Splat_128;",
        "",
        "   generic",
        "      type Vector_Type is private;",
        "      type Scalar_Type is private;",
        "      Instruction : String;",
        "      Store_Instruction : String;",
        "   function NEON_Integer_Reduce_128 (Value : Vector_Type) return Scalar_Type;",
        "   function NEON_Integer_Reduce_128 (Value : Vector_Type) return Scalar_Type is",
        "      Result : Scalar_Type;",
        "   begin",
        "      Asm (Template => \"ldr q0, [%1]\" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & Store_Instruction,",
        "           Inputs => [System.Address'Asm_Input (\"r\", Result'Address), System.Address'Asm_Input (\"r\", Value'Address)],",
        "           Clobber => \"v0,v1,v2,memory\", Volatile => True);",
        "      return Result;",
        "   end NEON_Integer_Reduce_128;",
        "",
        "   generic",
        "      type Vector_Type is private;",
        "      type Scalar_Type is private;",
        "      Instruction : String;",
        "      Store_Instruction : String;",
        "   function NEON_Float_Reduce_128 (Value : Vector_Type) return Scalar_Type;",
        "   function NEON_Float_Reduce_128 (Value : Vector_Type) return Scalar_Type is",
        "      Result : Scalar_Type;",
        "   begin",
        "      Asm (Template => \"ldr q0, [%1]\" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & Store_Instruction,",
        "           Inputs => [System.Address'Asm_Input (\"r\", Result'Address), System.Address'Asm_Input (\"r\", Value'Address)],",
        "           Clobber => \"v0,v1,v2,memory\", Volatile => True);",
        "      return Result;",
        "   end NEON_Float_Reduce_128;",
        "",
        "   generic",
        "      type Source_Type is private;",
        "      type Result_Type is private;",
        "      Instruction : String;",
        "   function NEON_Convert_128 (Value : Source_Type) return Result_Type;",
        "   function NEON_Convert_128 (Value : Source_Type) return Result_Type is",
        "      Result : Result_Type;",
        "   begin",
        "      Asm (Template => \"ldr q0, [%1]\" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & \"str q0, [%0]\",",
        "           Inputs => [System.Address'Asm_Input (\"r\", Result'Address), System.Address'Asm_Input (\"r\", Value'Address)],",
        "           Clobber => \"v0,v1,v2,memory\", Volatile => True);",
        "      return Result;",
        "   end NEON_Convert_128;",
        "",
        "   generic",
        "      type Source_Type is private;",
        "      type Result_Type is private;",
        "      Instruction : String;",
        "   function NEON_Convert_Pair_128 (Low, High : Source_Type) return Result_Type;",
        "   function NEON_Convert_Pair_128 (Low, High : Source_Type) return Result_Type is",
        "      Result : Result_Type;",
        "   begin",
        "      Asm (Template => \"ldr q0, [%1]\" & ASCII.LF & ASCII.HT & \"ldr q1, [%2]\" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & \"str q0, [%0]\",",
        "           Inputs => [System.Address'Asm_Input (\"r\", Result'Address), System.Address'Asm_Input (\"r\", Low'Address), System.Address'Asm_Input (\"r\", High'Address)],",
        "           Clobber => \"v0,v1,memory\", Volatile => True);",
        "      return Result;",
        "   end NEON_Convert_Pair_128;",
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
        "           Clobber => \"v0,v1,v2,x9,memory\", Volatile => True);",
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
        "      Test_Instruction : String;",
        "   function NEON_Select_128 (Bits : Interfaces.Unsigned_64; Weights : System.Address; If_True, If_False : Vector_Type) return Vector_Type;",
        "   function NEON_Select_128 (Bits : Interfaces.Unsigned_64; Weights : System.Address; If_True, If_False : Vector_Type) return Vector_Type is",
        "      Result : Vector_Type;",
        "   begin",
        "      Asm (Template => Dup_Instruction & ASCII.LF & ASCII.HT &",
        "           \"ldr q3, [%4]\" & ASCII.LF & ASCII.HT & Test_Instruction & ASCII.LF & ASCII.HT &",
        "           \"ldr q0, [%2]\" & ASCII.LF & ASCII.HT & \"ldr q1, [%3]\" & ASCII.LF & ASCII.HT &",
        "           \"bsl v2.16b, v0.16b, v1.16b\" & ASCII.LF & ASCII.HT & \"str q2, [%0]\",",
        "           Inputs => [System.Address'Asm_Input (\"r\", Result'Address), Interfaces.Unsigned_64'Asm_Input (\"r\", Bits), System.Address'Asm_Input (\"r\", If_True'Address), System.Address'Asm_Input (\"r\", If_False'Address), System.Address'Asm_Input (\"r\", Weights)],",
        "           Clobber => \"v0,v1,v2,v3,memory\", Volatile => True);",
        "      return Result;",
        "   end NEON_Select_128;",
        "",
        "   generic",
        "      type Vector_Type is private;",
        "   function NEON_Select_16_Lanes_128 (Bits : Interfaces.Unsigned_16; Weights : System.Address; If_True, If_False : Vector_Type) return Vector_Type;",
        "   function NEON_Select_16_Lanes_128 (Bits : Interfaces.Unsigned_16; Weights : System.Address; If_True, If_False : Vector_Type) return Vector_Type is",
        "      Result : Vector_Type;",
        "   begin",
        "      Asm (Template => \"dup v2.16b, %w1\" & ASCII.LF & ASCII.HT &",
        "           \"lsr w9, %w1, #8\" & ASCII.LF & ASCII.HT & \"dup v3.16b, w9\" & ASCII.LF & ASCII.HT &",
        "           \"ins v2.d[1], v3.d[0]\" & ASCII.LF & ASCII.HT & \"ldr q3, [%4]\" & ASCII.LF & ASCII.HT &",
        "           \"cmtst v2.16b, v2.16b, v3.16b\" & ASCII.LF & ASCII.HT &",
        "           \"ldr q0, [%2]\" & ASCII.LF & ASCII.HT & \"ldr q1, [%3]\" & ASCII.LF & ASCII.HT &",
        "           \"bsl v2.16b, v0.16b, v1.16b\" & ASCII.LF & ASCII.HT & \"str q2, [%0]\",",
        "           Inputs => [System.Address'Asm_Input (\"r\", Result'Address), Interfaces.Unsigned_16'Asm_Input (\"r\", Bits), System.Address'Asm_Input (\"r\", If_True'Address), System.Address'Asm_Input (\"r\", If_False'Address), System.Address'Asm_Input (\"r\", Weights)],",
        "           Clobber => \"v0,v1,v2,v3,x9,memory\", Volatile => True);",
        "      return Result;",
        "   end NEON_Select_16_Lanes_128;",
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


def native_lane_slides(architecture: str) -> list[str]:
    """Emit immediate-count native leaves and one public dispatcher per type."""
    out: list[str] = []
    generic = "NEON_Unary_128" if architecture == "aarch64" else "SSE2_Unary_128"
    for vector, _, bits, lanes in value_types():
        lane_bytes = bits // 8
        for name, toward_low in (
            ("Slide_Lanes_Toward_Low", True),
            ("Slide_Lanes_Toward_High", False),
        ):
            cases: list[str] = []
            for count in range(1, lanes):
                byte_count = count * lane_bytes
                native = f"Native_{name}_{vector}_{count}"
                if architecture == "aarch64":
                    ext_count = byte_count if toward_low else 16 - byte_count
                    operands = "v0.16b, v1.16b" if toward_low else "v1.16b, v0.16b"
                    instruction = (
                        "movi v1.16b, #0" + '" & ASCII.LF & ASCII.HT & "' +
                        f"ext v0.16b, {operands}, #{ext_count}"
                    )
                else:
                    opcode = "psrldq" if toward_low else "pslldq"
                    instruction = f"{opcode} ${byte_count}, %%xmm0"
                out.append(
                    f"   function {native} is new {generic} ({vector}, \"{instruction}\");"
                )
                out.append(f"   pragma Inline_Always ({native});")
                cases.append(f"         when {count} => {native} (Value)")
            out += [
                f"   function {name} (Value : {vector}; Count : Natural) return {vector} is",
                f"     (if Count = 0 then Value",
                f"      elsif Count >= {lanes} then Flyology_SIMD.Zero",
                "      else (case Count is",
                ",\n".join(cases) + ",",
                "         when others => Flyology_SIMD.Zero));",
                "",
            ]
    return out


def neon_compress_expand(vector: str, bits: int, lanes: int) -> list[str]:
    """Build a semantic byte map in Ada and perform lane movement with TBL."""
    idx = lane_index(bits, lanes)
    mask = mask_for(bits, lanes)
    mapping = lane_map(bits, lanes)
    lane_bytes = bits // 8
    native = f"Native_Permute_{vector}"
    storage = "Interfaces.Unsigned_16" if lanes == 16 else "Interfaces.Unsigned_8"
    test = (
        f"(Bits and Interfaces.Shift_Left ({storage}'(1), "
        "{lane})) /= 0"
    )
    return [
        f"   function Compress (Value : {vector}; Mask : {mask}) return {vector} is",
        f"      Map : {mapping};",
        f"      Bits : constant {storage} := Mask.Bits;",
        "      Result_Lane : Natural := 0;",
        "   begin",
        f"      for Source_Lane in {idx} loop",
        f"         if {test.format(lane='Source_Lane')} then",
        f"            for Byte in Natural range 0 .. {lane_bytes - 1} loop",
        "               Map.Byte_Indices",
        f"                 (Result_Lane * {lane_bytes} + Byte) :=",
        f"                   U8 (Source_Lane * {lane_bytes} + Byte);",
        "            end loop;",
        "            Result_Lane := Result_Lane + 1;",
        "         end if;",
        "      end loop;",
        f"      while Result_Lane < {lanes} loop",
        f"         for Byte in Natural range 0 .. {lane_bytes - 1} loop",
        "            Map.Byte_Indices",
        f"              (Result_Lane * {lane_bytes} + Byte) := 16;",
        "         end loop;",
        "         Result_Lane := Result_Lane + 1;",
        "      end loop;",
        f"      return {native} (Value, Map);",
        "   end Compress;",
        "",
        f"   function Expand (Value : {vector}; Mask : {mask}) return {vector} is",
        f"      Map : {mapping};",
        f"      Bits : constant {storage} := Mask.Bits;",
        "      Source_Lane : Natural := 0;",
        "   begin",
        f"      for Result_Lane in {idx} loop",
        f"         for Byte in Natural range 0 .. {lane_bytes - 1} loop",
        "            Map.Byte_Indices",
        f"              (Result_Lane * {lane_bytes} + Byte) :=",
        f"                (if {test.format(lane='Result_Lane')} then",
        f"                    U8 (Source_Lane * {lane_bytes} + Byte)",
        "                 else 16);",
        "         end loop;",
        f"         if {test.format(lane='Result_Lane')} then",
        "            Source_Lane := Source_Lane + 1;",
        "         end if;",
        "      end loop;",
        f"      return {native} (Value, Map);",
        "   end Expand;",
        "",
    ]


def neon_body() -> str:
    out = neon_helpers()
    for bits, lanes in ((16, 8), (32, 4), (64, 2)):
        scalar = f"U{bits}"
        vals = lane_values(f"{scalar}x{lanes}")
        out += [f"   Weights_{bits}x{lanes} : aliased constant {vals} := [{', '.join(str(1 << n) for n in range(lanes))}];"]
    out.append("")

    for source_vector, _, target_vector, _ in bit_cast_pairs():
        out.append(call("Bit_Cast", target_vector, "Value", f"Value : {source_vector}"))

    widen_instruction = {
        "U8x16": ("uxtl v0.8h, v0.8b", "uxtl2 v0.8h, v0.16b"),
        "I8x16": ("sxtl v0.8h, v0.8b", "sxtl2 v0.8h, v0.16b"),
        "U16x8": ("uxtl v0.4s, v0.4h", "uxtl2 v0.4s, v0.8h"),
        "I16x8": ("sxtl v0.4s, v0.4h", "sxtl2 v0.4s, v0.8h"),
        "U32x4": ("uxtl v0.2d, v0.2s", "uxtl2 v0.2d, v0.4s"),
        "I32x4": ("sxtl v0.2d, v0.2s", "sxtl2 v0.2d, v0.4s"),
        "F32x4": ("fcvtl v0.2d, v0.2s", "fcvtl2 v0.2d, v0.4s"),
    }
    for source_vector, _, target_vector, _, _, _ in WIDENINGS:
        for name, instruction in zip(("Widen_Low", "Widen_High"), widen_instruction[source_vector]):
            native = f"Native_{name}_{source_vector}_To_{target_vector}"
            out += [
                f"   function {native} is new NEON_Convert_128 ({source_vector}, {target_vector}, \"{instruction}\");",
                f"   function {name} (Value : {source_vector}) return {target_vector} is ({native} (Value));",
            ]
    for source_vector, _, target_vector, _, _ in FLOAT_WIDENINGS:
        for name, instruction in zip(("Widen_Low", "Widen_High"), widen_instruction[source_vector]):
            native = f"Native_{name}_{source_vector}_To_{target_vector}"
            out += [
                f"   function {native} is new NEON_Convert_128 ({source_vector}, {target_vector}, \"{instruction}\");",
                f"   function {name} (Value : {source_vector}) return {target_vector} is ({native} (Value));",
            ]

    lane_suffix = {
        8: ("8b", "16b", "8h"),
        16: ("4h", "8h", "4s"),
        32: ("2s", "4s", "2d"),
    }
    for source_vector, _, target_vector, _, target_bits, _, signed in NARROWINGS:
        low_shape, full_shape, source_shape = lane_suffix[target_bits]
        narrow = "sqxtn" if signed else "uqxtn"
        for name, opcode in (("Narrow_Truncate", "xtn"), ("Narrow_Saturate", narrow)):
            instruction = (
                f"{opcode} v0.{low_shape}, v0.{source_shape}" +
                '" & ASCII.LF & ASCII.HT & "' +
                f"{opcode}2 v0.{full_shape}, v1.{source_shape}"
            )
            native = f"Native_{name}_{source_vector}_To_{target_vector}"
            out += [
                f"   function {native} is new NEON_Convert_Pair_128 ({source_vector}, {target_vector}, \"{instruction}\");",
                f"   function {name} (Low, High : {source_vector}) return {target_vector} is ({native} (Low, High));",
            ]
    for source_vector, _, target_vector, _, target_bits, _, _ in SIGNED_TO_UNSIGNED_NARROWINGS:
        low_shape, full_shape, source_shape = lane_suffix[target_bits]
        instruction = (
            f"sqxtun v0.{low_shape}, v0.{source_shape}" +
            '" & ASCII.LF & ASCII.HT & "' +
            f"sqxtun2 v0.{full_shape}, v1.{source_shape}"
        )
        native = f"Native_Narrow_Saturate_{source_vector}_To_{target_vector}"
        out += [
            f"   function {native} is new NEON_Convert_Pair_128 ({source_vector}, {target_vector}, \"{instruction}\");",
            f"   function Narrow_Saturate (Low, High : {source_vector}) return {target_vector} is ({native} (Low, High));",
        ]
    for source_vector, _, target_vector, _, _ in FLOAT_NARROWINGS:
        instruction = (
            "fcvtn v0.2s, v0.2d" +
            '" & ASCII.LF & ASCII.HT & "' +
            "fcvtn2 v0.4s, v1.2d"
        )
        native = f"Native_Narrow_Round_{source_vector}_To_{target_vector}"
        out += [
            f"   function {native} is new NEON_Convert_Pair_128 ({source_vector}, {target_vector}, \"{instruction}\");",
            f"   function Narrow_Round (Low, High : {source_vector}) return {target_vector} is ({native} (Low, High));",
        ]
    for source_vector, _, target_vector, _, bits, _, signed in INTEGER_TO_FLOAT_CONVERSIONS:
        prefix = "scvtf" if signed else "ucvtf"
        shape = "4s" if bits == 32 else "2d"
        instruction = f"{prefix} v0.{shape}, v0.{shape}"
        native = f"Native_Convert_Round_{source_vector}_To_{target_vector}"
        out += [
            f"   function {native} is new NEON_Convert_128 ({source_vector}, {target_vector}, \"{instruction}\");",
            f"   function Convert_Round (Value : {source_vector}) return {target_vector} is ({native} (Value));",
        ]
    for source_vector, _, target_vector, _, bits, _, signed in FLOAT_TO_INTEGER_CONVERSIONS:
        prefix = "fcvtzs" if signed else "fcvtzu"
        shape = "4s" if bits == 32 else "2d"
        instruction = f"{prefix} v0.{shape}, v0.{shape}"
        native = f"Native_Convert_Truncate_Saturate_{source_vector}_To_{target_vector}"
        out += [
            f"   function {native} is new NEON_Convert_128 ({source_vector}, {target_vector}, \"{instruction}\");",
            f"   function Convert_Truncate_Saturate (Value : {source_vector}) return {target_vector} is ({native} (Value));",
        ]
    for source_vector, _, target_vector, _, bits, _, signed in SIGNED_UNSIGNED_CONVERSIONS:
        shape = f"{128 // bits}{ {8: 'b', 16: 'h', 32: 's', 64: 'd'}[bits]}"
        if signed and bits < 64:
            instruction = (
                "movi v1.2d, #0" + '" & ASCII.LF & ASCII.HT & "' +
                f"smax v0.{shape}, v0.{shape}, v1.{shape}"
            )
        elif signed:
            instruction = (
                "cmge v1.2d, v0.2d, #0" + '" & ASCII.LF & ASCII.HT & "' +
                "and v0.16b, v0.16b, v1.16b"
            )
        elif bits < 64:
            instruction = (
                "movi v1.16b, #0xff" + '" & ASCII.LF & ASCII.HT & "' +
                f"ushr v1.{shape}, v1.{shape}, #1" + '" & ASCII.LF & ASCII.HT & "' +
                f"umin v0.{shape}, v0.{shape}, v1.{shape}"
            )
        else:
            instruction = (
                "movi v1.16b, #0xff" + '" & ASCII.LF & ASCII.HT & "' +
                "ushr v1.2d, v1.2d, #1" + '" & ASCII.LF & ASCII.HT & "' +
                "cmhi v2.2d, v0.2d, v1.2d" + '" & ASCII.LF & ASCII.HT & "' +
                "bsl v2.16b, v1.16b, v0.16b" + '" & ASCII.LF & ASCII.HT & "' +
                "mov v0.16b, v2.16b"
            )
        native = f"Native_Convert_Saturate_{source_vector}_To_{target_vector}"
        out += [
            f"   function {native} is new NEON_Convert_128 ({source_vector}, {target_vector}, \"{instruction}\");",
            f"   function Convert_Saturate (Value : {source_vector}) return {target_vector} is ({native} (Value));",
        ]
    out += [
        "   function Native_Table_Lookup_U8x16 is new NEON_Binary_128 (U8x16, \"tbl v0.16b, {v0.16b}, v1.16b\");",
        "   function Table_Lookup (Table, Indices : U8x16) return U8x16 is (Native_Table_Lookup_U8x16 (Table, Indices));",
        "   function Native_Permute_U8x16 is new NEON_Permute_128 (U8x16, Lane_Map_8x16);",
        "   pragma Inline_Always (Native_Permute_U8x16);",
        "   function Permute_Lanes (Value : U8x16; Map : Lane_Map_8x16) return U8x16 is (Native_Permute_U8x16 (Value, Map));",
        "   function Native_Permute_2_U8x16 is new NEON_Permute_2_128 (U8x16, Two_Source_Lane_Map_8x16);",
        "   pragma Inline_Always (Native_Permute_2_U8x16);",
        "   function Permute_Lanes (Left, Right : U8x16; Map : Two_Source_Lane_Map_8x16) return U8x16 is (Native_Permute_2_U8x16 (Left, Right, Map));",
    ]
    out += neon_compress_expand("U8x16", 8, 16)
    out.append("")
    out += native_lane_slides("aarch64")

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
            "Min": (f"{prefix}min v0.{shape}, v0.{shape}, v1.{shape}" if bits < 64 else f"cm{'gt' if signed else 'hi'} v2.2d, v0.2d, v1.2d"),
            "Max": (f"{prefix}max v0.{shape}, v0.{shape}, v1.{shape}" if bits < 64 else f"cm{'gt' if signed else 'hi'} v2.2d, v0.2d, v1.2d"),
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
            *target_construction_body("aarch64", vector, scalar, bits, lanes),
            *direct_lane_access_body(vector, scalar, vals, idx),
            f"   function Native_Permute_{vector} is new NEON_Permute_128 ({vector}, {lane_map(bits, lanes)});",
            f"   pragma Inline_Always (Native_Permute_{vector});",
            f"   function Permute_Lanes (Value : {vector}; Map : {lane_map(bits, lanes)}) return {vector} is (Native_Permute_{vector} (Value, Map));",
            f"   function Native_Permute_2_{vector} is new NEON_Permute_2_128 ({vector}, {two_source_lane_map(bits, lanes)});",
            f"   pragma Inline_Always (Native_Permute_2_{vector});",
            f"   function Permute_Lanes (Left, Right : {vector}; Map : {two_source_lane_map(bits, lanes)}) return {vector} is (Native_Permute_2_{vector} (Left, Right, Map));",
        ]
        out += neon_compress_expand(vector, bits, lanes)
        if bits == 64:
            out += [
                f"   function Native_Multiply_Wrap_{vector} is new NEON_Multiply_64_128 ({vector});",
                f"   function Multiply_Wrap (Left, Right : {vector}) return {vector} is (Native_Multiply_Wrap_{vector} (Left, Right));",
            ]
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
            (
                f"   function Native_Select_{vector} is new NEON_Select_16_Lanes_128 ({vector});\n"
                f"   function Select_Value (Mask : {mask}; If_True, If_False : {vector}) return {vector} is "
                f"(Native_Select_{vector} (Mask.Bits, Weights_8x16'Address, If_True, If_False));"
                if lanes == 16
                else
                f"   function Native_Select_{vector} is new NEON_Select_128 ({vector}, \"dup v2.{shape}, %{'1' if bits == 64 else 'w1'}\", \"cmtst v2.{shape}, v2.{shape}, v3.{shape}\");\n"
                f"   function Select_Value (Mask : {mask}; If_True, If_False : {vector}) return {vector} is "
                f"(Native_Select_{vector} (Interfaces.Unsigned_64 (Mask.Bits), Weights_{bits}x{lanes}'Address, If_True, If_False));"
            ),
        ]
        scalar_lane = {8: "b", 16: "h", 32: "s", 64: "d"}[bits]
        store = f"str {scalar_lane}0, [%0]"
        if bits < 64:
            reduce_instructions = {
                "Reduce_Add_Wrap": f"addv {scalar_lane}0, v0.{shape}",
                "Reduce_Min": f"{prefix}minv {scalar_lane}0, v0.{shape}",
                "Reduce_Max": f"{prefix}maxv {scalar_lane}0, v0.{shape}",
            }
        else:
            compare = "cmgt" if signed else "cmhi"
            reduce_instructions = {
                "Reduce_Add_Wrap": "addp d0, v0.2d",
                "Reduce_Min": (
                    "dup v1.2d, v0.d[1]\n      "
                    + f"{compare} v2.2d, v0.2d, v1.2d\n      "
                    + "bit v0.16b, v1.16b, v2.16b"
                ),
                "Reduce_Max": (
                    "dup v1.2d, v0.d[1]\n      "
                    + f"{compare} v2.2d, v0.2d, v1.2d\n      "
                    + "bif v0.16b, v1.16b, v2.16b"
                ),
            }
        for name, instruction in reduce_instructions.items():
            ada_instruction = instruction.replace(
                "\n      ", '" & ASCII.LF & ASCII.HT & "'
            )
            native = f"Native_{name}_{vector}"
            out += [
                f"   function {native} is new NEON_Integer_Reduce_128 ({vector}, {scalar}, \"{ada_instruction}\", \"{store}\");",
                f"   function {name} (Value : {vector}) return {scalar} is ({native} (Value));",
            ]
        out += memory_body(vector, arr, count)

    for vector, scalar, bits, lanes in FLOAT_TYPES:
        idx, vals, mask = lane_index(bits, lanes), lane_values(vector), mask_for(bits, lanes)
        arr, count = array_name(scalar), lane_count(bits, lanes)
        shape = f"{lanes}{'s' if bits == 32 else 'd'}"
        weight = f"Weights_{bits}x{lanes}'Address"
        add_lane = "s" if bits == 32 else "d"
        add_steps = [
            '"mov v2.16b, v0.16b"',
            '"movi v0.16b, #0"',
        ]
        for lane in range(lanes):
            add_steps.extend([
                f'"dup v1.{shape}, v2.{add_lane}[{lane}]"',
                f'"fadd {add_lane}0, {add_lane}0, {add_lane}1"',
            ])
        add_instruction = " & ASCII.LF & ASCII.HT & ".join(add_steps)
        add_store = f"str {add_lane}0, [%0]"
        for name, op in (("Add", "fadd"), ("Subtract", "fsub"), ("Multiply", "fmul"), ("Divide", "fdiv"), ("Min_Number", "fminnm"), ("Max_Number", "fmaxnm"), ("Interleave_Low", "zip1"), ("Interleave_High", "zip2"), ("Deinterleave_Even", "uzp1"), ("Deinterleave_Odd", "uzp2")):
            instruction = f"{op} v0.{shape}, v0.{shape}, v1.{shape}"
            out += [f"   function Native_{name}_{vector} is new NEON_Binary_128 ({vector}, \"{instruction}\");", f"   function {name} (Left, Right : {vector}) return {vector} is (Native_{name}_{vector} (Left, Right));"]
        reverse = ("rev64 v0.4s, v0.4s\" & ASCII.LF & ASCII.HT & \"ext v0.16b, v0.16b, v0.16b, #8" if bits == 32 else "ext v0.16b, v0.16b, v0.16b, #8")
        out += [f"   function Native_Reverse_{vector} is new NEON_Unary_128 ({vector}, \"{reverse}\");", f"   function Reverse_Lanes (Value : {vector}) return {vector} is (Native_Reverse_{vector} (Value));"]
        for name, instruction in (("Equal", "fcmeq"), ("Greater_Than", "fcmgt"), ("Greater_Equal", "fcmge")):
            out += [f"   function Compare_{name}_{vector} is new NEON_Compare_128 ({vector}, \"{instruction} v0.{shape}, v0.{shape}, v1.{shape}\", {compact(bits)});", f"   function {name} (Left, Right : {vector}) return {mask} is (Mask_From_Bit_Mask (Compare_{name}_{vector} (Left, Right, {weight})));"]
        unordered = (
            f"fcmeq v0.{shape}, v0.{shape}, v0.{shape}"
            f'" & ASCII.LF & ASCII.HT & "fcmeq v1.{shape}, v1.{shape}, v1.{shape}'
            '" & ASCII.LF & ASCII.HT & "and v0.16b, v0.16b, v1.16b'
            '" & ASCII.LF & ASCII.HT & "mvn v0.16b, v0.16b'
        )
        out += [
            f"   function Compare_Unordered_{vector} is new NEON_Compare_128 ({vector}, \"{unordered}\", {compact(bits)});",
            f"   function Unordered (Left, Right : {vector}) return {mask} is (Mask_From_Bit_Mask (Compare_Unordered_{vector} (Left, Right, {weight})));",
            f"   function Less_Than (Left, Right : {vector}) return {mask} is (Greater_Than (Left => Right, Right => Left));",
            f"   function Less_Equal (Left, Right : {vector}) return {mask} is (Greater_Equal (Left => Right, Right => Left));",
            *target_construction_body("aarch64", vector, scalar, bits, lanes),
            *direct_lane_access_body(vector, scalar, vals, idx),
            f"   function Native_Permute_{vector} is new NEON_Permute_128 ({vector}, {lane_map(bits, lanes)});",
            f"   pragma Inline_Always (Native_Permute_{vector});",
            f"   function Permute_Lanes (Value : {vector}; Map : {lane_map(bits, lanes)}) return {vector} is (Native_Permute_{vector} (Value, Map));",
            f"   function Native_Permute_2_{vector} is new NEON_Permute_2_128 ({vector}, {two_source_lane_map(bits, lanes)});",
            f"   pragma Inline_Always (Native_Permute_2_{vector});",
            f"   function Permute_Lanes (Left, Right : {vector}; Map : {two_source_lane_map(bits, lanes)}) return {vector} is (Native_Permute_2_{vector} (Left, Right, Map));",
            f"   function Native_Select_{vector} is new NEON_Select_128 ({vector}, \"dup v2.{shape}, %{'1' if bits == 64 else 'w1'}\", \"cmtst v2.{shape}, v2.{shape}, v3.{shape}\");",
            f"   function Select_Value (Mask : {mask}; If_True, If_False : {vector}) return {vector} is (Native_Select_{vector} (Interfaces.Unsigned_64 (Mask.Bits), Weights_{bits}x{lanes}'Address, If_True, If_False));",
            f"   function Native_Reduce_Add_{vector} is new NEON_Float_Reduce_128 ({vector}, {scalar}, {add_instruction}, \"{add_store}\");",
            f"   function Reduce_Add (Value : {vector}) return {scalar} is (Native_Reduce_Add_{vector} (Value));",
        ]
        out += neon_compress_expand(vector, bits, lanes)
        for name, opcode in (("Reduce_Min_Number", "fminnm"), ("Reduce_Max_Number", "fmaxnm")):
            if bits == 32:
                instruction = (
                    '"mov v2.16b, v0.16b" & ASCII.LF & ASCII.HT & '
                    '"dup v1.4s, v2.s[1]" & ASCII.LF & ASCII.HT & '
                    f'"{opcode} s0, s0, s1" & ASCII.LF & ASCII.HT & '
                    '"dup v1.4s, v2.s[2]" & ASCII.LF & ASCII.HT & '
                    f'"{opcode} s0, s0, s1" & ASCII.LF & ASCII.HT & '
                    '"dup v1.4s, v2.s[3]" & ASCII.LF & ASCII.HT & '
                    f'"{opcode} s0, s0, s1"'
                )
                store = "str s0, [%0]"
            else:
                instruction = (
                    '"mov v2.16b, v0.16b" & ASCII.LF & ASCII.HT & '
                    '"dup v1.2d, v2.d[1]" & ASCII.LF & ASCII.HT & '
                    f'"{opcode} d0, d0, d1"'
                )
                store = "str d0, [%0]"
            native = f"Native_{name}_{vector}"
            out += [
                f"   function {native} is new NEON_Float_Reduce_128 ({vector}, {scalar}, {instruction}, \"{store}\");",
                f"   function {name} (Value : {vector}) return {scalar} is ({native} (Value));",
            ]
        out += memory_body(vector, arr, count)

    for bits, lanes, storage in MASKS:
        mask, idx, count = mask_for(bits, lanes), lane_index(bits, lanes), lane_count(bits, lanes)
        out += native_mask_body(bits, lanes, storage)
        out += [f"   function Population_Count (Mask : {mask}) return {count} is (Count_Set_Bits (Interfaces.Unsigned_32 (Mask.Bits)));", f"   function First_True (Mask : {mask}) return {count} is (Find_First_Set_Bit (Interfaces.Unsigned_32 (Mask.Bits), {lanes}));", f"   function Last_True (Mask : {mask}) return {count} is (Find_Last_Set_Bit (Interfaces.Unsigned_32 (Mask.Bits), {lanes}));"]
    return "\n".join(out)


def memory_body(vector: str, arr: str, count: str) -> list[str]:
    scalar = next(item[1] for item in INTEGER_TYPES + FLOAT_TYPES if item[0] == vector)
    bits = next(item[2] for item in INTEGER_TYPES + FLOAT_TYPES if item[0] == vector)
    lanes = 128 // bits
    idx = lane_index(bits, lanes)
    zero = "0.0" if scalar in {"F32", "F64"} else "0"
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
        *direct_partial_memory_body(vector, arr, count, idx, zero),
    ]


def x86_helpers() -> list[str]:
    """SSE2-only leaves shared by the generated 128-bit x86 family."""
    return [
        "   Sign_8 : aliased constant Lane_Values_8x16 := [others => 16#80#];",
        "   Sign_16 : aliased constant Lane_Values_8x16 := [0, 16#80#, 0, 16#80#, 0, 16#80#, 0, 16#80#, 0, 16#80#, 0, 16#80#, 0, 16#80#, 0, 16#80#];",
        "   Sign_32 : aliased constant Lane_Values_8x16 := [0, 0, 0, 16#80#, 0, 0, 0, 16#80#, 0, 0, 0, 16#80#, 0, 0, 0, 16#80#];",
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
        "   function SSE2_Zero_128 return Vector_Type;",
        "   function SSE2_Zero_128 return Vector_Type is",
        "      Result : Vector_Type;",
        "   begin",
        '      Asm (Template => "pxor %%xmm0, %%xmm0" & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)",',
        '           Inputs => System.Address\'Asm_Input ("r", Result\'Address),',
        '           Clobber => "xmm0,memory", Volatile => True);',
        "      return Result;",
        "   end SSE2_Zero_128;",
        "",
        "   generic",
        "      type Vector_Type is private;",
        "      type Scalar_Type is private;",
        "      Load_Instruction : String;",
        "      Duplicate_Instruction : String;",
        "   function SSE2_Splat_128 (Value : Scalar_Type) return Vector_Type;",
        "   function SSE2_Splat_128 (Value : Scalar_Type) return Vector_Type is",
        "      Result : Vector_Type;",
        "   begin",
        '      Asm (Template => Load_Instruction & ASCII.LF & ASCII.HT & Duplicate_Instruction & ASCII.LF & ASCII.HT & "movdqu %%xmm0, (%0)",',
        '           Inputs => [System.Address\'Asm_Input ("r", Result\'Address), System.Address\'Asm_Input ("r", Value\'Address)],',
        '           Clobber => "rax,xmm0,memory", Volatile => True);',
        "      return Result;",
        "   end SSE2_Splat_128;",
        "",
        "   generic",
        "      type Source_Type is private;",
        "      type Result_Type is private;",
        "      Instruction : String;",
        "   function SSE2_Convert_128 (Value : Source_Type) return Result_Type;",
        "   function SSE2_Convert_128 (Value : Source_Type) return Result_Type is",
        "      Result : Result_Type;",
        "   begin",
        "      Asm (Template => \"movdqu (%1), %%xmm0\" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & \"movdqu %%xmm0, (%0)\", Inputs => [System.Address'Asm_Input (\"r\", Result'Address), System.Address'Asm_Input (\"r\", Value'Address)], Clobber => \"rax,rcx,rdx,r8,xmm0,xmm1,xmm2,xmm3,xmm4,xmm5,xmm6,xmm7,cc,memory\", Volatile => True);",
        "      return Result;",
        "   end SSE2_Convert_128;",
        "",
        "   generic",
        "      type Source_Type is private;",
        "      type Result_Type is private;",
        "      Instruction : String;",
        "   function SSE2_Convert_Pair_128 (Low, High : Source_Type) return Result_Type;",
        "   function SSE2_Convert_Pair_128 (Low, High : Source_Type) return Result_Type is",
        "      Result : Result_Type;",
        "   begin",
        "      Asm (Template => \"movdqu (%1), %%xmm0\" & ASCII.LF & ASCII.HT & \"movdqu (%2), %%xmm1\" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & \"movdqu %%xmm0, (%0)\", Inputs => [System.Address'Asm_Input (\"r\", Result'Address), System.Address'Asm_Input (\"r\", Low'Address), System.Address'Asm_Input (\"r\", High'Address)], Clobber => \"xmm0,xmm1,xmm2,xmm3,xmm4,xmm5,xmm6,xmm7,memory\", Volatile => True);",
        "      return Result;",
        "   end SSE2_Convert_Pair_128;",
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
        "      Asm (Template => \"movdqu (%1), %%xmm0\" & ASCII.LF & ASCII.HT & \"movd (%2), %%xmm1\" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & \"movdqu %%xmm0, (%0)\", Inputs => [System.Address'Asm_Input (\"r\", Result'Address), System.Address'Asm_Input (\"r\", Value'Address), System.Address'Asm_Input (\"r\", Local_Count'Address)], Clobber => \"xmm0,xmm1,xmm2,xmm3,memory\", Volatile => True);",
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
        "   generic",
        "      type Vector_Type is private;",
        "      type Scalar_Type is private;",
        "      Instruction : String;",
        "      Store_Instruction : String;",
        "      Load_Sign : Boolean;",
        "   function SSE2_Integer_Reduce_128 (Value : Vector_Type; Sign : System.Address) return Scalar_Type;",
        "   function SSE2_Integer_Reduce_128 (Value : Vector_Type; Sign : System.Address) return Scalar_Type is",
        "      Result : Scalar_Type;",
        "   begin",
        "      Asm (Template => \"movdqu (%1), %%xmm0\" & ASCII.LF & ASCII.HT & (if Load_Sign then \"movdqu (%2), %%xmm7\" & ASCII.LF & ASCII.HT else \"\") & Instruction & ASCII.LF & ASCII.HT & Store_Instruction, Inputs => [System.Address'Asm_Input (\"r\", Result'Address), System.Address'Asm_Input (\"r\", Value'Address), System.Address'Asm_Input (\"r\", Sign)], Clobber => \"eax,xmm0,xmm1,xmm2,xmm3,xmm4,xmm5,xmm6,xmm7,memory\", Volatile => True);",
        "      return Result;",
        "   end SSE2_Integer_Reduce_128;",
        "",
        "   generic",
        "      type Vector_Type is private;",
        "      type Scalar_Type is private;",
        "      Instruction : String;",
        "      Store_Instruction : String;",
        "   function SSE2_Float_Reduce_128 (Value : Vector_Type) return Scalar_Type;",
        "   function SSE2_Float_Reduce_128 (Value : Vector_Type) return Scalar_Type is",
        "      Result : Scalar_Type;",
        "   begin",
        "      Asm (Template => \"movdqu (%1), %%xmm0\" & ASCII.LF & ASCII.HT & Instruction & ASCII.LF & ASCII.HT & Store_Instruction, Inputs => [System.Address'Asm_Input (\"r\", Result'Address), System.Address'Asm_Input (\"r\", Value'Address)], Clobber => \"xmm0,xmm1,xmm2,xmm3,xmm4,xmm5,xmm6,xmm7,memory\", Volatile => True);",
        "      return Result;",
        "   end SSE2_Float_Reduce_128;",
        "",
    ]


def x86_memory_body(vector: str, arr: str, count: str) -> list[str]:
    scalar = next(item[1] for item in INTEGER_TYPES + FLOAT_TYPES if item[0] == vector)
    bits = next(item[2] for item in INTEGER_TYPES + FLOAT_TYPES if item[0] == vector)
    lanes = 128 // bits
    idx = lane_index(bits, lanes)
    zero = "0.0" if scalar in {"F32", "F64"} else "0"
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
        *direct_partial_memory_body(vector, arr, count, idx, zero),
    ]


def x86_ada_instruction(instruction: str) -> str:
    return instruction.replace("\n", '" & ASCII.LF & ASCII.HT & "')


def x86_expand_lane_sign(register: str, bits: int) -> str:
    """Expand the high bit of each 32- or 64-bit lane to a full-lane mask."""
    if bits == 32:
        return f"psrad $31, %%{register}"
    assert bits == 64
    return (
        f"pshufd $0xF5, %%{register}, %%{register}\n"
        f"psrad $31, %%{register}"
    )


def x86_saturating_arithmetic_instruction(
    bits: int, signed: bool, subtract: bool
) -> str:
    """Return an SSE2-only saturating add or subtract for 32/64-bit lanes."""
    assert bits in (32, 64)
    packed = f"{'psub' if subtract else 'padd'}{'d' if bits == 32 else 'q'}"
    expand_overflow = x86_expand_lane_sign("xmm4", bits)

    if not signed:
        if subtract:
            # The high bit of (~A and B) or (~(A xor B) and (A - B)) is
            # the borrow out of an unsigned lane.  Convert it to a complete
            # lane mask, then clear every lane that borrowed.
            return (
                "movdqa %%xmm0, %%xmm2\n"
                "movdqa %%xmm1, %%xmm3\n"
                f"{packed} %%xmm1, %%xmm0\n"
                "pcmpeqd %%xmm6, %%xmm6\n"
                "movdqa %%xmm2, %%xmm4\n"
                "pxor %%xmm6, %%xmm4\n"
                "pand %%xmm3, %%xmm4\n"
                "pxor %%xmm3, %%xmm2\n"
                "pxor %%xmm6, %%xmm2\n"
                "pand %%xmm0, %%xmm2\n"
                "por %%xmm2, %%xmm4\n"
                f"{expand_overflow}\n"
                "pandn %%xmm0, %%xmm4\n"
                "movdqa %%xmm4, %%xmm0"
            )

        # The high bit of (A and B) or ((A or B) and not (A + B)) is the
        # carry out of an unsigned lane.  Expand it and set an overflowing
        # lane to all ones.
        return (
            "movdqa %%xmm0, %%xmm2\n"
            "movdqa %%xmm1, %%xmm3\n"
            f"{packed} %%xmm1, %%xmm0\n"
            "movdqa %%xmm2, %%xmm4\n"
            "pand %%xmm3, %%xmm4\n"
            "por %%xmm3, %%xmm2\n"
            "movdqa %%xmm0, %%xmm5\n"
            "pcmpeqd %%xmm6, %%xmm6\n"
            "pxor %%xmm6, %%xmm5\n"
            "pand %%xmm5, %%xmm2\n"
            "por %%xmm2, %%xmm4\n"
            f"{expand_overflow}\n"
            "por %%xmm4, %%xmm0"
        )

    # Signed addition overflows when equal-sign inputs produce a result with
    # the other sign.  Signed subtraction overflows when different-sign
    # inputs produce a result whose sign differs from the left input.
    overflow = (
        "movdqa %%xmm2, %%xmm4\n"
        "pxor %%xmm3, %%xmm4\n"
        + (
            "pcmpeqd %%xmm6, %%xmm6\n"
            "pxor %%xmm6, %%xmm4\n"
            if not subtract
            else ""
        )
        + "movdqa %%xmm2, %%xmm5\n"
        "pxor %%xmm0, %%xmm5\n"
        "pand %%xmm5, %%xmm4\n"
        f"{expand_overflow}\n"
    )
    sign_of_left = x86_expand_lane_sign("xmm5", bits)
    shift_left = "pslld $31" if bits == 32 else "psllq $63"
    shift_right = "psrld $1" if bits == 32 else "psrlq $1"
    return (
        "movdqa %%xmm0, %%xmm2\n"
        "movdqa %%xmm1, %%xmm3\n"
        f"{packed} %%xmm1, %%xmm0\n"
        f"{overflow}"
        "pcmpeqd %%xmm6, %%xmm6\n"
        "movdqa %%xmm6, %%xmm7\n"
        f"{shift_left}, %%xmm7\n"
        f"{shift_right}, %%xmm6\n"
        "movdqa %%xmm2, %%xmm5\n"
        f"{sign_of_left}\n"
        "movdqa %%xmm5, %%xmm2\n"
        "pand %%xmm7, %%xmm2\n"
        "pandn %%xmm6, %%xmm5\n"
        "por %%xmm2, %%xmm5\n"
        "pand %%xmm4, %%xmm5\n"
        "pandn %%xmm0, %%xmm4\n"
        "por %%xmm5, %%xmm4\n"
        "movdqa %%xmm4, %%xmm0"
    )


def x86_reduction_shuffles(bits: int) -> list[str]:
    """Return fixed SSE2 permutations for an associative lane reduction."""
    shuffles = [
        "pshufd $0x4E, %%xmm6, %%xmm1",
    ]
    if bits <= 32:
        shuffles.append("pshufd $0xB1, %%xmm6, %%xmm1")
    if bits <= 16:
        shuffles.append(
            "movdqa %%xmm6, %%xmm1\n"
            "pshuflw $0xB1, %%xmm1, %%xmm1\n"
            "pshufhw $0xB1, %%xmm1, %%xmm1"
        )
    if bits == 8:
        shuffles.append(
            "movdqa %%xmm6, %%xmm1\n"
            "movdqa %%xmm1, %%xmm3\n"
            "psrlw $8, %%xmm1\n"
            "psllw $8, %%xmm3\n"
            "por %%xmm3, %%xmm1"
        )
    return shuffles


def x86_reduce_add_instruction(bits: int) -> str:
    lane = {8: "b", 16: "w", 32: "d", 64: "q"}[bits]
    shifts = {8: (8, 4, 2, 1), 16: (8, 4, 2), 32: (8, 4), 64: (8,)}[bits]
    return "\n".join(
        f"movdqa %%xmm0, %%xmm1\npsrldq ${shift}, %%xmm1\npadd{lane} %%xmm1, %%xmm0"
        for shift in shifts
    )


def x86_float_reduce_add_instruction(bits: int, lanes: int) -> str:
    """Return an ordered floating reduction that starts from positive zero."""
    operation = "addss" if bits == 32 else "addsd"
    shift = 4 if bits == 32 else 8
    steps = ["movdqa %%xmm0, %%xmm2", "pxor %%xmm0, %%xmm0"]
    for lane in range(lanes):
        steps.append(f"{operation} %%xmm2, %%xmm0")
        if lane + 1 < lanes:
            steps.append(f"psrldq ${shift}, %%xmm2")
    return "\n".join(steps)


def x86_convert_round_64_instruction(signed: bool) -> str:
    """Convert two integer64 lanes to binary64 under the current MXCSR mode."""
    if signed:
        return "\n".join(
            [
                "movq %%xmm0, %%rax",
                "cvtsi2sdq %%rax, %%xmm2",
                "psrldq $8, %%xmm0",
                "movq %%xmm0, %%rax",
                "cvtsi2sdq %%rax, %%xmm3",
                "unpcklpd %%xmm3, %%xmm2",
                "movdqa %%xmm2, %%xmm0",
            ]
        )

    def lane(target: str, high: bool, label: int) -> list[str]:
        load = ["psrldq $8, %%xmm0"] if high else []
        return load + [
            "movq %%xmm0, %%rax",
            "testq %%rax, %%rax",
            f"js {label}f",
            f"cvtsi2sdq %%rax, %%{target}",
            f"jmp {label + 1}f",
            f"{label}:",
            "movq %%rax, %%rcx",
            "shrq $1, %%rcx",
            "andq $1, %%rax",
            "orq %%rax, %%rcx",
            f"cvtsi2sdq %%rcx, %%{target}",
            f"addsd %%{target}, %%{target}",
            f"{label + 1}:",
        ]

    return "\n".join(
        lane("xmm2", False, 1)
        + lane("xmm3", True, 3)
        + ["unpcklpd %%xmm3, %%xmm2", "movdqa %%xmm2, %%xmm0"]
    )


def x86_convert_truncate_saturate_f64_instruction(signed: bool) -> str:
    """Convert two binary64 lanes to saturated integer64 results."""

    def signed_lane(target: str, high: bool, label: int) -> list[str]:
        load = ["psrldq $8, %%xmm0"] if high else []
        return load + [
            "movq %%xmm0, %%rax",
            "cvttsd2siq %%xmm0, %%rcx",
            "movq %%rax, %%r8",
            "movabsq $0x7fffffffffffffff, %%rdx",
            "andq %%rdx, %%r8",
            "movabsq $0x7ff0000000000000, %%rdx",
            "cmpq %%rdx, %%r8",
            f"ja {label}f",
            "movabsq $0x8000000000000000, %%rdx",
            "cmpq %%rdx, %%rcx",
            f"jne {label + 2}f",
            "testq %%rax, %%rax",
            f"js {label + 2}f",
            "movabsq $0x7fffffffffffffff, %%rcx",
            f"jmp {label + 2}f",
            f"{label}:",
            "xorq %%rcx, %%rcx",
            f"{label + 2}:",
            f"movq %%rcx, %%{target}",
        ]

    def unsigned_lane(target: str, high: bool, label: int) -> list[str]:
        load = ["psrldq $8, %%xmm0"] if high else []
        return load + [
            "movq %%xmm0, %%rax",
            "testq %%rax, %%rax",
            f"js {label}f",
            "movabsq $0x7ff0000000000000, %%rdx",
            "cmpq %%rdx, %%rax",
            f"ja {label}f",
            "movabsq $0x43f0000000000000, %%rdx",
            "cmpq %%rdx, %%rax",
            f"jae {label + 1}f",
            "movabsq $0x43e0000000000000, %%rdx",
            "cmpq %%rdx, %%rax",
            f"jae {label + 2}f",
            "cvttsd2siq %%xmm0, %%rcx",
            f"jmp {label + 3}f",
            f"{label + 2}:",
            "movabsq $0x43e0000000000000, %%rdx",
            "movq %%rdx, %%xmm2",
            "movapd %%xmm0, %%xmm1",
            "subsd %%xmm2, %%xmm1",
            "cvttsd2siq %%xmm1, %%rcx",
            "movabsq $0x8000000000000000, %%rdx",
            "orq %%rdx, %%rcx",
            f"jmp {label + 3}f",
            f"{label + 1}:",
            "movabsq $0xffffffffffffffff, %%rcx",
            f"jmp {label + 3}f",
            f"{label}:",
            "xorq %%rcx, %%rcx",
            f"{label + 3}:",
            f"movq %%rcx, %%{target}",
        ]

    make_lane = signed_lane if signed else unsigned_lane
    first_label, second_label = (1, 5) if signed else (1, 6)
    return "\n".join(
        make_lane("xmm4", False, first_label)
        + make_lane("xmm5", True, second_label)
        + ["punpcklqdq %%xmm5, %%xmm4", "movdqa %%xmm4, %%xmm0"]
    )


def x86_float_minmax_instruction(bits: int, maximum: bool) -> str:
    """Return an SSE2 number-minimum/maximum with the public edge rules.

    The implementation uses integer operations only.  This avoids the
    operand-order rules of MINP*/MAXP* and avoids raising an invalid exception
    while classifying a signaling NaN.  XMM6 and XMM7 retain the original
    operands while XMM0 accumulates the result.
    """
    assert bits in (32, 64)
    def select(mask: str, candidate: str) -> list[str]:
        return [
            f"movdqa %%{mask}, %%xmm2",
            f"movdqa %%{candidate}, %%xmm3",
            f"pand %%{mask}, %%xmm3",
            "pandn %%xmm0, %%xmm2",
            "por %%xmm2, %%xmm3",
            "movdqa %%xmm3, %%xmm0",
        ]

    def nan_mask(source: str, signaling: bool) -> list[str]:
        if bits == 32:
            lines = [
                f"movdqa %%{source}, %%xmm3",
                "pcmpeqd %%xmm4, %%xmm4",
                "psrld $1, %%xmm4",
                "pand %%xmm4, %%xmm3",
                "pcmpeqd %%xmm4, %%xmm4",
                "pslld $24, %%xmm4",
                "psrld $1, %%xmm4",
                "pcmpgtd %%xmm4, %%xmm3",
                f"movdqa %%{source}, %%xmm4",
                "pslld $9, %%xmm4",
                "psrad $31, %%xmm4",
            ]
        else:
            # Absolute IEEE encodings fit in signed 64-bit order.  Compare
            # each absolute value with positive infinity using the high signed
            # dword and, when equal, the low unsigned dword.
            lines = [
                f"movdqa %%{source}, %%xmm1",
                "pcmpeqd %%xmm2, %%xmm2",
                "psrlq $1, %%xmm2",
                "pand %%xmm2, %%xmm1",
                "pcmpeqd %%xmm3, %%xmm3",
                "psllq $53, %%xmm3",
                "psrlq $1, %%xmm3",
                "movdqa %%xmm1, %%xmm4",
                "pcmpgtd %%xmm3, %%xmm4",
                "pshufd $0xF5, %%xmm4, %%xmm4",
                "movdqa %%xmm1, %%xmm5",
                "pcmpeqd %%xmm3, %%xmm5",
                "pshufd $0xF5, %%xmm5, %%xmm5",
                "pcmpeqd %%xmm2, %%xmm2",
                "pslld $31, %%xmm2",
                "pxor %%xmm2, %%xmm1",
                "pxor %%xmm2, %%xmm3",
                "pcmpgtd %%xmm3, %%xmm1",
                "pshufd $0xA0, %%xmm1, %%xmm1",
                "pand %%xmm5, %%xmm1",
                "por %%xmm1, %%xmm4",
                "movdqa %%xmm4, %%xmm3",
                f"movdqa %%{source}, %%xmm4",
                "psllq $12, %%xmm4",
                "pshufd $0xF5, %%xmm4, %%xmm4",
                "psrad $31, %%xmm4",
            ]
        lines.append(
            "pandn %%xmm3, %%xmm4"
            if signaling
            else "pand %%xmm3, %%xmm4"
        )
        return lines

    def quiet(source: str) -> list[str]:
        lines = [f"movdqa %%{source}, %%xmm5", "pcmpeqd %%xmm3, %%xmm3"]
        if bits == 32:
            lines += ["pslld $31, %%xmm3", "psrld $9, %%xmm3"]
        else:
            lines += ["psllq $63, %%xmm3", "psrlq $12, %%xmm3"]
        lines.append("por %%xmm3, %%xmm5")
        return lines

    lines = ["movdqa %%xmm0, %%xmm6", "movdqa %%xmm1, %%xmm7"]
    if bits == 32:
        lines += [
            "movdqa %%xmm6, %%xmm2",
            "movdqa %%xmm6, %%xmm3",
            "psrad $31, %%xmm3",
            "psrld $1, %%xmm3",
            "pxor %%xmm3, %%xmm2",
            "movdqa %%xmm7, %%xmm4",
            "movdqa %%xmm7, %%xmm5",
            "psrad $31, %%xmm5",
            "psrld $1, %%xmm5",
            "pxor %%xmm5, %%xmm4",
        ]
        if maximum:
            lines.append("pcmpgtd %%xmm4, %%xmm2")
        else:
            lines += ["pcmpgtd %%xmm2, %%xmm4", "movdqa %%xmm4, %%xmm2"]
    else:
        # Create monotonically ordered signed keys for each binary64 value.
        lines += [
            "movdqa %%xmm6, %%xmm2",
            "movdqa %%xmm6, %%xmm3",
            "pshufd $0xF5, %%xmm3, %%xmm3",
            "psrad $31, %%xmm3",
            "psrlq $1, %%xmm3",
            "pxor %%xmm3, %%xmm2",
            "movdqa %%xmm7, %%xmm4",
            "movdqa %%xmm7, %%xmm5",
            "pshufd $0xF5, %%xmm5, %%xmm5",
            "psrad $31, %%xmm5",
            "psrlq $1, %%xmm5",
            "pxor %%xmm5, %%xmm4",
        ]
        left_key, right_key = ("xmm2", "xmm4") if maximum else ("xmm4", "xmm2")
        lines += [
            f"movdqa %%{left_key}, %%xmm3",
            f"pcmpgtd %%{right_key}, %%xmm3",
            "pshufd $0xF5, %%xmm3, %%xmm3",
            f"movdqa %%{left_key}, %%xmm5",
            f"pcmpeqd %%{right_key}, %%xmm5",
            "pshufd $0xF5, %%xmm5, %%xmm5",
            "pcmpeqd %%xmm0, %%xmm0",
            "pslld $31, %%xmm0",
            "pxor %%xmm0, %%xmm2",
            "pxor %%xmm0, %%xmm4",
        ]
        if maximum:
            lines += ["pcmpgtd %%xmm4, %%xmm2", "pshufd $0xA0, %%xmm2, %%xmm2"]
        else:
            lines += [
                "pcmpgtd %%xmm2, %%xmm4",
                "pshufd $0xA0, %%xmm4, %%xmm4",
                "movdqa %%xmm4, %%xmm2",
            ]
        lines += ["pand %%xmm5, %%xmm2", "por %%xmm3, %%xmm2"]

    # A strict ordered comparison selects Left; equality selects Right.  The
    # integer keys order negative zero below positive zero, so this also gives
    # the documented zero result without executing a floating comparison.
    lines += [
        "movdqa %%xmm2, %%xmm3",
        "pand %%xmm6, %%xmm3",
        "pandn %%xmm7, %%xmm2",
        "por %%xmm3, %%xmm2",
        "movdqa %%xmm2, %%xmm0",
    ]

    # Apply lower-priority quiet NaNs first.  A quiet left operand selects the
    # right number; a quiet right operand selects the left number.  Applying
    # the left mask second also reproduces the scalar two-qNaN result.
    lines += nan_mask("xmm7", signaling=False)
    lines += select("xmm4", "xmm6")
    lines += nan_mask("xmm6", signaling=False)
    lines += select("xmm4", "xmm7")

    # A signaling NaN wins over a quiet NaN or number and is returned with its
    # quiet bit set.  The left signaling operand has final precedence.
    lines += nan_mask("xmm7", signaling=True)
    lines += quiet("xmm7")
    lines += select("xmm4", "xmm5")
    lines += nan_mask("xmm6", signaling=True)
    lines += quiet("xmm6")
    lines += select("xmm4", "xmm5")
    return "\n".join(lines)


def x86_float_reduce_minmax_instruction(
    bits: int, lanes: int, maximum: bool
) -> str:
    """Apply the exact scalar min/max rule from lane 0 in ascending order."""
    shift = 4 if bits == 32 else 8
    steps: list[str] = []
    for lane in range(1, lanes):
        steps += [
            "movdqu (%1), %%xmm1",
            f"psrldq ${lane * shift}, %%xmm1",
            x86_float_minmax_instruction(bits, maximum),
        ]
    return "\n".join(steps)


def x86_reduce_extreme_instruction(
    bits: int, compare: str, maximum: bool, native_instruction: str | None = None
) -> str:
    stages: list[str] = []
    for shuffle in x86_reduction_shuffles(bits):
        if native_instruction is not None:
            stages.extend([
                "movdqa %%xmm0, %%xmm6",
                shuffle,
                f"{native_instruction} %%xmm1, %%xmm0",
            ])
            continue
        stages.extend([
            "movdqa %%xmm0, %%xmm6",
            shuffle,
            compare,
            "movdqa %%xmm0, %%xmm2",
            "movdqa %%xmm0, %%xmm4",
            "movdqa %%xmm6, %%xmm0",
            shuffle,
        ])
        if maximum:
            stages.extend([
                "pand %%xmm0, %%xmm4",
                "pandn %%xmm1, %%xmm2",
            ])
        else:
            stages.extend([
                "pandn %%xmm0, %%xmm2",
                "pand %%xmm1, %%xmm4",
            ])
        stages.extend(["por %%xmm4, %%xmm2", "movdqa %%xmm2, %%xmm0"])
    return "\n".join(stages)


def x86_reduce_store(bits: int) -> str:
    return {
        8: "movd %%xmm0, %%eax\nmovb %%al, (%0)",
        16: "pextrw $0, %%xmm0, %%eax\nmovw %%ax, (%0)",
        32: "movd %%xmm0, (%0)",
        64: "movq %%xmm0, (%0)",
    }[bits]


def x86_widen_instruction(bits: int, signed: bool, high: bool) -> str:
    """Return one SSE2 sign- or zero-extension sequence."""
    compare = {8: "pcmpgtb", 16: "pcmpgtw", 32: "pcmpgtd"}[bits]
    unpack = {
        8: "punpckhbw" if high else "punpcklbw",
        16: "punpckhwd" if high else "punpcklwd",
        32: "punpckhdq" if high else "punpckldq",
    }[bits]
    lines = ["pxor %%xmm1, %%xmm1"]
    if signed:
        lines.append(f"{compare} %%xmm0, %%xmm1")
    lines.append(f"{unpack} %%xmm1, %%xmm0")
    return "\n".join(lines)


def x86_truncate_instruction(target_bits: int) -> str:
    """Keep the low half of every source lane and concatenate both inputs."""
    if target_bits == 8:
        return (
            "pcmpeqd %%xmm2, %%xmm2\npsrlw $8, %%xmm2\n"
            "pand %%xmm2, %%xmm0\npand %%xmm2, %%xmm1\n"
            "packuswb %%xmm1, %%xmm0"
        )
    if target_bits == 16:
        return (
            "pshuflw $0x88, %%xmm0, %%xmm0\n"
            "pshufhw $0x88, %%xmm0, %%xmm0\n"
            "pshufd $0x88, %%xmm0, %%xmm0\n"
            "pshuflw $0x88, %%xmm1, %%xmm1\n"
            "pshufhw $0x88, %%xmm1, %%xmm1\n"
            "pshufd $0x88, %%xmm1, %%xmm1\n"
            "punpcklqdq %%xmm1, %%xmm0"
        )
    return (
        "pshufd $0x88, %%xmm0, %%xmm0\n"
        "pshufd $0x88, %%xmm1, %%xmm1\n"
        "punpcklqdq %%xmm1, %%xmm0"
    )


def x86_clamp_unsigned_instruction(target_bits: int) -> str:
    """Clamp unsigned source lanes to the unsigned result range."""
    if target_bits == 8:
        lines = [
            "pxor %%xmm7, %%xmm7",
            "pcmpeqd %%xmm6, %%xmm6",
            "psrlw $8, %%xmm6",
        ]
        for register, scratch in (("%%xmm0", "%%xmm2"), ("%%xmm1", "%%xmm3")):
            lines += [
                f"movdqa {register}, {scratch}",
                f"psrlw $8, {scratch}",
                f"pcmpeqw %%xmm7, {scratch}",
                f"pand {scratch}, {register}",
                f"pandn %%xmm6, {scratch}",
                f"por {scratch}, {register}",
            ]
        return "\n".join(lines) + "\npackuswb %%xmm1, %%xmm0"
    shift = target_bits
    lines = [
        "pxor %%xmm7, %%xmm7",
        "pcmpeqd %%xmm6, %%xmm6",
        f"psrld ${shift}, %%xmm6" if target_bits == 16 else "",
    ]
    for register, scratch in (("%%xmm0", "%%xmm2"), ("%%xmm1", "%%xmm3")):
        lines += [
            f"movdqa {register}, {scratch}",
            f"psrl{'d' if target_bits == 16 else 'q'} ${shift}, {scratch}",
            f"pcmpeq{'d' if target_bits == 16 else 'q'} %%xmm7, {scratch}"
            if target_bits == 16
            else f"pshufd $0xA0, {scratch}, {scratch}\npcmpeqd %%xmm7, {scratch}",
            f"pand {scratch}, {register}",
            f"pandn %%xmm6, {scratch}",
            f"por {scratch}, {register}",
        ]
    return "\n".join(line for line in lines if line) + "\n" + x86_truncate_instruction(target_bits)


def x86_clamp_signed_to_unsigned_instruction(target_bits: int) -> str:
    """Clamp signed source lanes to zero through the unsigned result maximum."""
    if target_bits == 8:
        return "packuswb %%xmm1, %%xmm0"
    if target_bits == 16:
        lines = [
            "pxor %%xmm7, %%xmm7",
            "pcmpeqd %%xmm6, %%xmm6",
            "psrld $16, %%xmm6",
        ]
        for register in ("%%xmm0", "%%xmm1"):
            lines += [
                "movdqa %%xmm7, %%xmm2",
                f"pcmpgtd {register}, %%xmm2",
                f"pandn {register}, %%xmm2",
                "movdqa %%xmm2, %%xmm3",
                "pcmpgtd %%xmm6, %%xmm3",
                "movdqa %%xmm3, %%xmm4",
                "pand %%xmm6, %%xmm4",
                "pandn %%xmm2, %%xmm3",
                "por %%xmm4, %%xmm3",
                f"movdqa %%xmm3, {register}",
            ]
        return "\n".join(lines) + "\n" + x86_truncate_instruction(target_bits)
    lines = ["pxor %%xmm7, %%xmm7", "pcmpeqd %%xmm6, %%xmm6"]
    for register in ("%%xmm0", "%%xmm1"):
        lines += [
            f"movdqa {register}, %%xmm2",
            "pshufd $0xF5, %%xmm2, %%xmm2",
            "movdqa %%xmm2, %%xmm3",
            "psrad $31, %%xmm3",
            "pcmpeqd %%xmm7, %%xmm2",
            f"pand %%xmm2, {register}",
            "por %%xmm3, %%xmm2",
            "pandn %%xmm6, %%xmm2",
            f"por %%xmm2, {register}",
        ]
    return "\n".join(lines) + "\n" + x86_truncate_instruction(target_bits)


def x86_clamp_signed_instruction(target_bits: int) -> str:
    """Clamp signed source lanes to the signed result range."""
    if target_bits == 8:
        return "packsswb %%xmm1, %%xmm0"
    if target_bits == 16:
        return "packssdw %%xmm1, %%xmm0"
    lines = ["pcmpeqd %%xmm5, %%xmm5", "psrld $1, %%xmm5"]
    for register in ("%%xmm0", "%%xmm1"):
        lines += [
            f"movdqa {register}, %%xmm2",
            "pshufd $0xF5, %%xmm2, %%xmm2",
            f"movdqa {register}, %%xmm3",
            "pshufd $0xA0, %%xmm3, %%xmm3",
            "psrad $31, %%xmm3",
            "pcmpeqd %%xmm3, %%xmm2",
            f"movdqa {register}, %%xmm3",
            "pshufd $0xF5, %%xmm3, %%xmm3",
            "psrad $31, %%xmm3",
            "pxor %%xmm5, %%xmm3",
            f"pand %%xmm2, {register}",
            "pandn %%xmm3, %%xmm2",
            f"por %%xmm2, {register}",
        ]
    return "\n".join(lines) + "\n" + x86_truncate_instruction(target_bits)


def x86_convert_saturate_instruction(bits: int, signed_source: bool) -> str:
    """Clamp signedness-changing lanes without changing their width."""
    suffix = {8: "b", 16: "w", 32: "d"}.get(bits)
    if bits == 64:
        sign_mask = (
            "movdqa %%xmm0, %%xmm1\n"
            "pshufd $0xF5, %%xmm1, %%xmm1\n"
            "psrad $31, %%xmm1"
        )
    else:
        sign_mask = (
            "pxor %%xmm1, %%xmm1\n"
            f"pcmpgt{suffix} %%xmm0, %%xmm1"
        )
    if signed_source:
        return sign_mask + "\npandn %%xmm0, %%xmm1\nmovdqa %%xmm1, %%xmm0"
    if bits == 8:
        signed_max = (
            "pcmpeqd %%xmm2, %%xmm2\n"
            "psrlw $9, %%xmm2\n"
            "packuswb %%xmm2, %%xmm2"
        )
    else:
        signed_max = (
            "pcmpeqd %%xmm2, %%xmm2\n"
            f"psrl{'q' if bits == 64 else suffix} $1, %%xmm2"
        )
    return (
        sign_mask
        + "\n" + signed_max + "\n"
        + "movdqa %%xmm1, %%xmm3\n"
        + "pand %%xmm2, %%xmm1\n"
        + "pandn %%xmm0, %%xmm3\n"
        + "por %%xmm1, %%xmm3\n"
        + "movdqa %%xmm3, %%xmm0"
    )


def x86_convert_round_32_instruction(signed_source: bool) -> str:
    """Convert four 32-bit integer lanes to binary32 with SSE2."""
    if signed_source:
        return "cvtdq2ps %%xmm0, %%xmm0"

    # cvtdq2ps accepts signed lanes.  Values with their high bit clear can use
    # it directly.  For the upper unsigned half, round (Value >> 1) with its
    # discarded bit folded in, then double the floating result.  This is the
    # standard exact round-to-nearest construction for all U32 inputs.
    return (
        "pxor %%xmm2, %%xmm2\n"
        "pcmpgtd %%xmm0, %%xmm2\n"
        "movdqa %%xmm0, %%xmm1\n"
        "psrld $1, %%xmm1\n"
        "pcmpeqd %%xmm3, %%xmm3\n"
        "psrld $31, %%xmm3\n"
        "movdqa %%xmm0, %%xmm4\n"
        "pand %%xmm3, %%xmm4\n"
        "por %%xmm4, %%xmm1\n"
        "cvtdq2ps %%xmm1, %%xmm1\n"
        "addps %%xmm1, %%xmm1\n"
        "cvtdq2ps %%xmm0, %%xmm0\n"
        "movdqa %%xmm2, %%xmm4\n"
        "pand %%xmm1, %%xmm4\n"
        "pandn %%xmm0, %%xmm2\n"
        "por %%xmm4, %%xmm2\n"
        "movdqa %%xmm2, %%xmm0"
    )


def x86_f32_limit_2_31(register: str, scratch: str) -> str:
    """Construct packed binary32 2**31 without a data-table dependency."""
    return (
        f"pcmpeqd %%{register}, %%{register}\n"
        f"movdqa %%{register}, %%{scratch}\n"
        f"psrld $28, %%{scratch}\n"
        f"pslld $24, %%{scratch}\n"
        f"psrld $31, %%{register}\n"
        f"pslld $30, %%{register}\n"
        f"por %%{scratch}, %%{register}"
    )


def x86_convert_truncate_saturate_f32_instruction(signed_target: bool) -> str:
    """Truncate four binary32 lanes and clamp them to a 32-bit range."""
    limit = x86_f32_limit_2_31("xmm6", "xmm7")
    if signed_target:
        # cvttps2dq supplies every in-range truncated result.  Packed compares
        # identify both saturation boundaries independently; unordered lanes
        # are cleared last so every NaN maps to zero.
        return (
            "movdqa %%xmm0, %%xmm1\n"
            "cvttps2dq %%xmm1, %%xmm1\n"
            f"{limit}\n"
            "movdqa %%xmm6, %%xmm2\n"
            "cmpleps %%xmm0, %%xmm2\n"
            "pcmpeqd %%xmm7, %%xmm7\n"
            "pslld $31, %%xmm7\n"
            "movdqa %%xmm6, %%xmm3\n"
            "por %%xmm7, %%xmm3\n"
            "movdqa %%xmm0, %%xmm4\n"
            "cmpleps %%xmm3, %%xmm4\n"
            "movdqa %%xmm0, %%xmm5\n"
            "cmpunordps %%xmm5, %%xmm5\n"
            "pcmpeqd %%xmm6, %%xmm6\n"
            "psrld $1, %%xmm6\n"
            "movdqa %%xmm6, %%xmm3\n"
            "pand %%xmm2, %%xmm3\n"
            "pandn %%xmm1, %%xmm2\n"
            "por %%xmm3, %%xmm2\n"
            "movdqa %%xmm7, %%xmm3\n"
            "pand %%xmm4, %%xmm3\n"
            "pandn %%xmm2, %%xmm4\n"
            "por %%xmm3, %%xmm4\n"
            "pandn %%xmm4, %%xmm5\n"
            "movdqa %%xmm5, %%xmm0"
        )

    # Split the unsigned range at 2**31.  The upper half is converted after
    # subtracting 2**31 and then has its integer high bit restored.  Negative
    # and unordered lanes become zero; lanes at or above 2**32 become U32'Last.
    return (
        f"{limit}\n"
        "movdqa %%xmm6, %%xmm2\n"
        "cmpleps %%xmm0, %%xmm2\n"
        "movdqa %%xmm6, %%xmm3\n"
        "addps %%xmm3, %%xmm3\n"
        "cmpleps %%xmm0, %%xmm3\n"
        "movdqa %%xmm0, %%xmm4\n"
        "cmpunordps %%xmm4, %%xmm4\n"
        "pxor %%xmm7, %%xmm7\n"
        "movdqa %%xmm0, %%xmm5\n"
        "cmpltps %%xmm7, %%xmm5\n"
        "por %%xmm5, %%xmm4\n"
        "movdqa %%xmm0, %%xmm1\n"
        "cvttps2dq %%xmm1, %%xmm1\n"
        "movdqa %%xmm0, %%xmm5\n"
        "subps %%xmm6, %%xmm5\n"
        "cvttps2dq %%xmm5, %%xmm5\n"
        "pcmpeqd %%xmm7, %%xmm7\n"
        "pslld $31, %%xmm7\n"
        "paddd %%xmm7, %%xmm5\n"
        "movdqa %%xmm2, %%xmm6\n"
        "pand %%xmm5, %%xmm6\n"
        "pandn %%xmm1, %%xmm2\n"
        "por %%xmm6, %%xmm2\n"
        "pcmpeqd %%xmm6, %%xmm6\n"
        "pand %%xmm3, %%xmm6\n"
        "pandn %%xmm2, %%xmm3\n"
        "por %%xmm6, %%xmm3\n"
        "pandn %%xmm3, %%xmm4\n"
        "movdqa %%xmm4, %%xmm0"
    )


def x86_body() -> str:
    out = x86_helpers()
    out.append(call("Table_Lookup", "U8x16", "Table, Indices", "Table, Indices : U8x16"))
    out.append(call("Permute_Lanes", "U8x16", "Value, Map", "Value : U8x16; Map : Lane_Map_8x16"))
    out.append(call("Permute_Lanes", "U8x16", "Left, Right, Map", "Left, Right : U8x16; Map : Two_Source_Lane_Map_8x16"))
    out.append(call("Compress", "U8x16", "Value, Mask", "Value : U8x16; Mask : Mask_8x16"))
    out.append(call("Expand", "U8x16", "Value, Mask", "Value : U8x16; Mask : Mask_8x16"))
    out += native_lane_slides("x86_64")
    for source_vector, _, target_vector, _ in bit_cast_pairs():
        out.append(call("Bit_Cast", target_vector, "Value", f"Value : {source_vector}"))
    for source_vector, _, target_vector, _, source_bits, _ in WIDENINGS:
        signed = source_vector.startswith("I")
        for name, high in (("Widen_Low", False), ("Widen_High", True)):
            native = f"Native_{name}_{source_vector}_To_{target_vector}"
            instruction = x86_ada_instruction(
                x86_widen_instruction(source_bits, signed, high)
            )
            out += [
                f"   function {native} is new SSE2_Convert_128 ({source_vector}, {target_vector}, \"{instruction}\");",
                f"   function {name} (Value : {source_vector}) return {target_vector} is ({native} (Value));",
            ]
    for source_vector, _, target_vector, _, _ in FLOAT_WIDENINGS:
        for name, raw_instruction in (
            ("Widen_Low", "cvtps2pd %%xmm0, %%xmm0"),
            (
                "Widen_High",
                "pshufd $0xEE, %%xmm0, %%xmm0\n"
                "cvtps2pd %%xmm0, %%xmm0",
            ),
        ):
            native = f"Native_{name}_{source_vector}_To_{target_vector}"
            instruction = x86_ada_instruction(raw_instruction)
            out += [
                f"   function {native} is new SSE2_Convert_128 ({source_vector}, {target_vector}, \"{instruction}\");",
                f"   function {name} (Value : {source_vector}) return {target_vector} is ({native} (Value));",
            ]
    for source_vector, _, target_vector, _, target_bits, _, signed in NARROWINGS:
        instructions = {
            "Narrow_Truncate": x86_truncate_instruction(target_bits),
            "Narrow_Saturate": (
                x86_clamp_signed_instruction(target_bits)
                if signed
                else x86_clamp_unsigned_instruction(target_bits)
            ),
        }
        for name, raw_instruction in instructions.items():
            native = f"Native_{name}_{source_vector}_To_{target_vector}"
            instruction = x86_ada_instruction(raw_instruction)
            out += [
                f"   function {native} is new SSE2_Convert_Pair_128 ({source_vector}, {target_vector}, \"{instruction}\");",
                f"   function {name} (Low, High : {source_vector}) return {target_vector} is ({native} (Low, High));",
            ]
    for source_vector, _, target_vector, _, target_bits, _, _ in SIGNED_TO_UNSIGNED_NARROWINGS:
        native = f"Native_Narrow_Saturate_{source_vector}_To_{target_vector}"
        instruction = x86_ada_instruction(
            x86_clamp_signed_to_unsigned_instruction(target_bits)
        )
        out += [
            f"   function {native} is new SSE2_Convert_Pair_128 ({source_vector}, {target_vector}, \"{instruction}\");",
            f"   function Narrow_Saturate (Low, High : {source_vector}) return {target_vector} is ({native} (Low, High));",
        ]
    for source_vector, _, target_vector, _, _ in FLOAT_NARROWINGS:
        native = f"Native_Narrow_Round_{source_vector}_To_{target_vector}"
        instruction = x86_ada_instruction(
            "cvtpd2ps %%xmm0, %%xmm0\n"
            "cvtpd2ps %%xmm1, %%xmm1\n"
            "movlhps %%xmm1, %%xmm0"
        )
        out += [
            f"   function {native} is new SSE2_Convert_Pair_128 ({source_vector}, {target_vector}, \"{instruction}\");",
            f"   function Narrow_Round (Low, High : {source_vector}) return {target_vector} is ({native} (Low, High));",
        ]
    for source_vector, _, target_vector, _, bits, _, signed in INTEGER_TO_FLOAT_CONVERSIONS:
        native = f"Native_Convert_Round_{source_vector}_To_{target_vector}"
        instruction = x86_ada_instruction(
            x86_convert_round_32_instruction(signed)
            if bits == 32
            else x86_convert_round_64_instruction(signed)
        )
        out += [
            f"   function {native} is new SSE2_Convert_128 ({source_vector}, {target_vector}, \"{instruction}\");",
            f"   function Convert_Round (Value : {source_vector}) return {target_vector} is ({native} (Value));",
        ]
    for source_vector, _, target_vector, _, bits, _, signed in FLOAT_TO_INTEGER_CONVERSIONS:
        native = (
            f"Native_Convert_Truncate_Saturate_{source_vector}_To_{target_vector}"
        )
        instruction = x86_ada_instruction(
            x86_convert_truncate_saturate_f32_instruction(signed)
            if bits == 32
            else x86_convert_truncate_saturate_f64_instruction(signed)
        )
        out += [
            f"   function {native} is new SSE2_Convert_128 ({source_vector}, {target_vector}, \"{instruction}\");",
            f"   function Convert_Truncate_Saturate (Value : {source_vector}) return {target_vector} is ({native} (Value));",
        ]
    for source_vector, _, target_vector, _, bits, _, signed in SIGNED_UNSIGNED_CONVERSIONS:
        native = f"Native_Convert_Saturate_{source_vector}_To_{target_vector}"
        instruction = x86_ada_instruction(
            x86_convert_saturate_instruction(bits, signed)
        )
        out += [
            f"   function {native} is new SSE2_Convert_128 ({source_vector}, {target_vector}, \"{instruction}\");",
            f"   function Convert_Saturate (Value : {source_vector}) return {target_vector} is ({native} (Value));",
        ]
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
        else:
            instructions["Add_Saturate"] = x86_saturating_arithmetic_instruction(
                bits, signed, False
            )
            instructions["Subtract_Saturate"] = x86_saturating_arithmetic_instruction(
                bits, signed, True
            )
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
            *target_construction_body("x86_64", vector, scalar, bits, lanes),
            *direct_lane_access_body(vector, scalar, vals, idx),
            call("Permute_Lanes", vector, "Value, Map", f"Value : {vector}; Map : {lane_map(bits, lanes)}"),
            call("Permute_Lanes", vector, "Left, Right, Map", f"Left, Right : {vector}; Map : {two_source_lane_map(bits, lanes)}"),
            call("Compress", vector, "Value, Mask", f"Value : {vector}; Mask : {mask}"),
            call("Expand", vector, "Value, Mask", f"Value : {vector}; Mask : {mask}"),
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
                instruction = x86_ada_instruction(
                    "movdqa %%xmm0, %%xmm2" + "\n"
                    "pshufd $0xF5, %%xmm2, %%xmm2" + "\n"
                    "psrad $31, %%xmm2" + "\n"
                    "psrlq %%xmm1, %%xmm0" + "\n"
                    "movdqa %%xmm2, %%xmm3" + "\n"
                    "psrlq %%xmm1, %%xmm3" + "\n"
                    "pxor %%xmm2, %%xmm3" + "\n"
                    "por %%xmm3, %%xmm0"
                )
                out += [
                    f"   function Native_SAR_{vector} is new SSE2_Shift_128 ({vector}, \"{instruction}\");",
                    f"   function Shift_Right_Arithmetic (Value : {vector}; Count : Natural) return {vector} is (Native_SAR_{vector} (Value, Interfaces.Unsigned_32 (Natural'Min (Count, {bits}))));",
                ]
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
        reduction_sign = (
            "Sign_8'Address" if bits == 8
            else "Sign_16'Address" if bits == 16
            else "Sign_32'Address"
        )
        reduction_compare = (signed_gt if signed else unsigned_gt)[bits]
        native_min = "pminsw" if signed and bits == 16 else None
        native_max = "pmaxsw" if signed and bits == 16 else None
        for name, instruction, load_sign in (
            ("Reduce_Add_Wrap", x86_reduce_add_instruction(bits), False),
            ("Reduce_Min", x86_reduce_extreme_instruction(bits, reduction_compare, False, native_min), (not signed or bits == 64) and native_min is None),
            ("Reduce_Max", x86_reduce_extreme_instruction(bits, reduction_compare, True, native_max), (not signed or bits == 64) and native_max is None),
        ):
            native = f"Native_{name}_{vector}"
            out += [
                f"   function {native} is new SSE2_Integer_Reduce_128 ({vector}, {scalar}, \"{x86_ada_instruction(instruction)}\", \"{x86_ada_instruction(x86_reduce_store(bits))}\", {str(load_sign)});",
                f"   function {name} (Value : {vector}) return {scalar} is ({native} (Value, {reduction_sign}));",
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
        reduce_instruction = x86_ada_instruction(
            x86_float_reduce_add_instruction(bits, lanes)
        )
        reduce_store = "movss %%xmm0, (%0)" if bits == 32 else "movsd %%xmm0, (%0)"
        min_instruction = x86_ada_instruction(
            x86_float_minmax_instruction(bits, maximum=False)
        )
        max_instruction = x86_ada_instruction(
            x86_float_minmax_instruction(bits, maximum=True)
        )
        reduce_min_instruction = x86_ada_instruction(
            x86_float_reduce_minmax_instruction(bits, lanes, maximum=False)
        )
        reduce_max_instruction = x86_ada_instruction(
            x86_float_reduce_minmax_instruction(bits, lanes, maximum=True)
        )
        out += [
            f"   function Greater_Than (Left, Right : {vector}) return {mask} is (Less_Than (Left => Right, Right => Left));",
            f"   function Greater_Equal (Left, Right : {vector}) return {mask} is (Less_Equal (Left => Right, Right => Left));",
            f"   function Native_Select_{vector} is new SSE2_Select_128 ({vector}, {bits});",
            f"   function Select_Value (Mask : {mask}; If_True, If_False : {vector}) return {vector} is (Native_Select_{vector} (Interfaces.Unsigned_16 (To_Bit_Mask (Mask)), {weights}, If_True, If_False));",
            *target_construction_body("x86_64", vector, scalar, bits, lanes),
            *direct_lane_access_body(vector, scalar, vals, idx),
            call("Permute_Lanes", vector, "Value, Map", f"Value : {vector}; Map : {lane_map(bits, lanes)}"),
            call("Permute_Lanes", vector, "Left, Right, Map", f"Left, Right : {vector}; Map : {two_source_lane_map(bits, lanes)}"),
            call("Compress", vector, "Value, Mask", f"Value : {vector}; Mask : {mask}"),
            call("Expand", vector, "Value, Mask", f"Value : {vector}; Mask : {mask}"),
            f"   function Native_Min_Number_{vector} is new SSE2_Binary_128 ({vector}, \"{min_instruction}\");",
            f"   function Min_Number (Left, Right : {vector}) return {vector} is (Native_Min_Number_{vector} (Left, Right));",
            f"   function Native_Max_Number_{vector} is new SSE2_Binary_128 ({vector}, \"{max_instruction}\");",
            f"   function Max_Number (Left, Right : {vector}) return {vector} is (Native_Max_Number_{vector} (Left, Right));",
            f"   function Native_Reduce_Add_{vector} is new SSE2_Float_Reduce_128 ({vector}, {scalar}, \"{reduce_instruction}\", \"{reduce_store}\");",
            f"   function Reduce_Add (Value : {vector}) return {scalar} is (Native_Reduce_Add_{vector} (Value));",
            f"   function Native_Reduce_Min_Number_{vector} is new SSE2_Float_Reduce_128 ({vector}, {scalar}, \"{reduce_min_instruction}\", \"{reduce_store}\");",
            f"   function Reduce_Min_Number (Value : {vector}) return {scalar} is (Native_Reduce_Min_Number_{vector} (Value));",
            f"   function Native_Reduce_Max_Number_{vector} is new SSE2_Float_Reduce_128 ({vector}, {scalar}, \"{reduce_max_instruction}\", \"{reduce_store}\");",
            f"   function Reduce_Max_Number (Value : {vector}) return {scalar} is (Native_Reduce_Max_Number_{vector} (Value));",
        ]
        out += x86_memory_body(vector, arr, count)

    for bits, lanes, storage in MASKS:
        mask, idx, count = mask_for(bits, lanes), lane_index(bits, lanes), lane_count(bits, lanes)
        out += native_mask_body(bits, lanes, storage)
        out += [f"   function Population_Count (Mask : {mask}) return {count} is (Count_Set_Bits (Interfaces.Unsigned_32 (To_Bit_Mask (Mask))));", f"   function First_True (Mask : {mask}) return {count} is (Find_First_Set_Bit (Interfaces.Unsigned_32 (To_Bit_Mask (Mask)), {lanes}));", f"   function Last_True (Mask : {mask}) return {count} is (Find_Last_Set_Bit (Interfaces.Unsigned_32 (To_Bit_Mask (Mask)), {lanes}));"]
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
        "   function Reference_First_True (Value, Lanes : Natural) return Natural is",
        "   begin",
        "      for Lane in Natural range 0 .. Lanes - 1 loop",
        "         if (Value / 2 ** Lane) mod 2 = 1 then return Lane; end if;",
        "      end loop;",
        "      return Lanes;",
        "   end Reference_First_True;", "",
        "   function Reference_Last_True (Value, Lanes : Natural) return Natural is",
        "   begin",
        "      for Lane in reverse Natural range 0 .. Lanes - 1 loop",
        "         if (Value / 2 ** Lane) mod 2 = 1 then return Lane; end if;",
        "      end loop;",
        "      return Lanes;",
        "   end Reference_Last_True;", "",
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
        saturation_edges = {
            "U32x4": [
                "      Saturation_Left : constant U32x4 := From_Lanes ([U32'Last, 0, U32'Last, 0]);",
                "      Saturation_Right : constant U32x4 := From_Lanes ([1, 1, U32'Last, U32'Last]);",
                "      Saturating_Add_Expected : constant Lane_Values_U32x4 := [U32'Last, 1, U32'Last, U32'Last];",
                "      Saturating_Subtract_Expected : constant Lane_Values_U32x4 := [U32'Last - 1, 0, 0, 0];",
            ],
            "I32x4": [
                "      Saturation_Left : constant I32x4 := From_Lanes ([I32'Last, I32'First, I32'Last, I32'First]);",
                "      Saturation_Right : constant I32x4 := From_Lanes ([1, -1, -1, 1]);",
                "      Saturating_Add_Expected : constant Lane_Values_I32x4 := [I32'Last, I32'First, I32'Last - 1, I32'First + 1];",
                "      Saturating_Subtract_Expected : constant Lane_Values_I32x4 := [I32'Last - 1, I32'First + 1, I32'Last, I32'First];",
            ],
            "U64x2": [
                "      Saturation_Left : constant U64x2 := From_Lanes ([U64'Last, 0]);",
                "      Saturation_Right : constant U64x2 := From_Lanes ([1, 1]);",
                "      Saturating_Add_Expected : constant Lane_Values_U64x2 := [U64'Last, 1];",
                "      Saturating_Subtract_Expected : constant Lane_Values_U64x2 := [U64'Last - 1, 0];",
            ],
            "I64x2": [
                "      Saturation_Left : constant I64x2 := From_Lanes ([I64'Last, I64'First]);",
                "      Saturation_Right : constant I64x2 := From_Lanes ([1, -1]);",
                "      Saturating_Add_Expected : constant Lane_Values_I64x2 := [I64'Last, I64'First];",
                "      Saturating_Subtract_Expected : constant Lane_Values_I64x2 := [I64'Last - 1, I64'First + 1];",
                "      Saturation_Left_2 : constant I64x2 := Saturation_Left;",
                "      Saturation_Right_2 : constant I64x2 := From_Lanes ([-1, 1]);",
                "      Saturating_Add_Expected_2 : constant Lane_Values_I64x2 := [I64'Last - 1, I64'First + 1];",
                "      Saturating_Subtract_Expected_2 : constant Lane_Values_I64x2 := [I64'Last, I64'First];",
            ],
        }.get(vector, [])
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
            f"   function Random_{vector}_Selectors return {lane_selectors(bits, lanes)} is",
            f"      Result : {lane_selectors(bits, lanes)};",
            "   begin",
            f"      for Lane in {lane_index(bits, lanes)} loop Result (Lane) := {lane_index(bits, lanes)} (Next_U64 mod {lanes}); end loop;",
            "      return Result;",
            f"   end Random_{vector}_Selectors;",
            f"   function Same (Left, Right : {vector}) return Boolean is (To_Lanes (Left) = To_Lanes (Right));",
            f"   function Reference_Compress_{vector} (Value : {vector}; Mask : {mask}) return {vector} is",
            f"      Result : {vector} := Zero;",
            "      Result_Lane : Natural := 0;",
            "   begin",
            f"      for Source_Lane in {lane_index(bits, lanes)} loop",
            "         if Test (Mask, Source_Lane) then",
            f"            Result := Replace (Result, {lane_index(bits, lanes)} (Result_Lane), Extract (Value, Source_Lane));",
            "            Result_Lane := Result_Lane + 1;",
            "         end if;",
            "      end loop;",
            "      return Result;",
            f"   end Reference_Compress_{vector};",
            f"   function Reference_Expand_{vector} (Value : {vector}; Mask : {mask}) return {vector} is",
            f"      Result : {vector} := Zero;",
            "      Source_Lane : Natural := 0;",
            "   begin",
            f"      for Result_Lane in {lane_index(bits, lanes)} loop",
            "         if Test (Mask, Result_Lane) then",
            f"            Result := Replace (Result, Result_Lane, Extract (Value, {lane_index(bits, lanes)} (Source_Lane)));",
            "            Source_Lane := Source_Lane + 1;",
            "         end if;",
            "      end loop;",
            "      return Result;",
            f"   end Reference_Expand_{vector};",
            *(
                [
                    "   function Reference_Shift_Right_Arithmetic_I64x2 (Value : I64x2; Count : Natural) return I64x2 is",
                    "      Result : I64x2 := Zero;",
                    "      Raw, Shifted : Interfaces.Unsigned_64;",
                    "   begin",
                    "      for Lane in Lane_Index_64x2 loop",
                    "         Raw := I64x2_To_Bits (Extract (Value, Lane));",
                    "         if Count = 0 then Shifted := Raw;",
                    "         elsif Count >= 64 then Shifted := (if Extract (Value, Lane) < 0 then Interfaces.Unsigned_64'Last else 0);",
                    "         elsif Extract (Value, Lane) < 0 then Shifted := Interfaces.Shift_Right (Raw, Count) or Interfaces.Shift_Left (Interfaces.Unsigned_64'Last, 64 - Count);",
                    "         else Shifted := Interfaces.Shift_Right (Raw, Count); end if;",
                    "         Result := Replace (Result, Lane, Bits_To_I64x2 (Shifted));",
                    "      end loop;",
                    "      return Result;",
                    "   end Reference_Shift_Right_Arithmetic_I64x2;",
                ]
                if vector == "I64x2" else []
            ),
            f"   procedure Test_{vector} is",
            f"      A : constant {vector} := From_Lanes ([{agg_a}]);",
            f"      B : constant {vector} := From_Lanes ([{agg_b}]);",
            f"      Fixed_Selectors : constant {lane_selectors(bits, lanes)} := [{', '.join(str((n * 3 + 1) % lanes) for n in range(lanes))}];",
            f"      Fixed_Map : constant {lane_map(bits, lanes)} := Make_Lane_Map (Fixed_Selectors);",
            f"      Broadcast_Map : constant {lane_map(bits, lanes)} := Make_Lane_Map ([others => {lanes - 1}]);",
            f"      Default_Map : {lane_map(bits, lanes)};",
            f"      Fixed_Two_Source_Map : constant {two_source_lane_map(bits, lanes)} := Make_Two_Source_Lane_Map ([for Lane in {lane_index(bits, lanes)} => (if Lane mod 2 = 0 then Select_Left_Lane ({lane_index(bits, lanes)} ((Lane * 3 + 1) mod {lanes})) else Select_Right_Lane ({lane_index(bits, lanes)} ((Lane * 3 + 1) mod {lanes})))]);",
            f"      Default_Two_Source_Map : {two_source_lane_map(bits, lanes)};",
            f"      Data, Reference : {arr} (0 .. {lanes + 5}) := [others => 0];",
            f"      Aligned_Data : {arr} (0 .. {lanes - 1}) := [others => 0] with Alignment => 16;",
            f"      Maximum_Index_Data : {arr} (Natural'Last .. Natural'Last) := [others => {scalar} (1)];",
            *saturation_edges,
            *(
                [
                    "      Multiply_Edge_Left : constant U64x2 := From_Lanes ([16#FFFF_FFFF_0000_0001#, 16#8000_0001_0000_0001#]);",
                    "      Multiply_Edge_Right : constant U64x2 := From_Lanes ([16#0000_0002_FFFF_FFFF#, 16#FFFF_FFFF_0000_0003#]);",
                    "      Multiply_Edge_Expected : constant Lane_Values_U64x2 := [16#0000_0003_FFFF_FFFF#, 16#8000_0002_0000_0003#];",
                ]
                if vector == "U64x2"
                else (
                    [
                        "      Multiply_Edge_Left : constant I64x2 := From_Lanes ([Bits_To_I64x2 (16#8000_0000_0000_0000#), Bits_To_I64x2 (16#7FFF_FFFF_0000_0001#)]);",
                        "      Multiply_Edge_Right : constant I64x2 := From_Lanes ([Bits_To_I64x2 (16#FFFF_FFFF_FFFF_FFFF#), Bits_To_I64x2 (16#FFFF_FFFE_0000_0003#)]);",
                        "      Multiply_Edge_Expected : constant Lane_Values_I64x2 := [Bits_To_I64x2 (16#8000_0000_0000_0000#), Bits_To_I64x2 (16#7FFF_FFFB_0000_0003#)];",
                    ]
                    if vector == "I64x2"
                    else []
                )
            ),
            "   begin",
            f"      Check (To_Lanes (A) = [{agg_a}], \"{vector} scalar lane construction\");",
            f"      for Lane in {lane_index(bits, lanes)} loop Check (Extract ({vector}'(Backends.Native.Zero), Lane) = 0 and then Extract (Backends.Native.Splat (To_Lanes (A) (0)), Lane) = To_Lanes (A) (0), \"{vector} independent native construction\" & Lane'Image); end loop;",
            f"      for Lane in {lane_index(bits, lanes)} loop Check (Extract (Backends.Native.Splat ({scalar}'Last), Lane) = {scalar}'Last, \"{vector} maximum-value native splat\" & Lane'Image); end loop;",
            *(
                [f"      for Lane in {lane_index(bits, lanes)} loop Check (Extract (Backends.Native.Splat ({scalar}'First), Lane) = {scalar}'First, \"{vector} minimum-value native splat\" & Lane'Image); end loop;"]
                if signed
                else []
            ),
            f"      Check (To_Lanes (Backends.Native.From_Lanes (To_Lanes (A))) = To_Lanes (A) and then Backends.Native.To_Lanes (A) = To_Lanes (A), \"{vector} independent native lane construction\");",
            f"      for Lane in {lane_index(bits, lanes)} loop",
            f"         Check (Extract (A, Lane) = To_Lanes (A) (Lane), \"{vector} scalar extract\" & Lane'Image);",
            f"         Check (Extract (Replace (A, Lane, To_Lanes (B) (Lane)), Lane) = To_Lanes (B) (Lane), \"{vector} scalar replace\" & Lane'Image);",
            f"         Check (Backends.Native.Extract (A, Lane) = To_Lanes (A) (Lane), \"{vector} independent native extract\" & Lane'Image);",
            f"         for Result_Lane in {lane_index(bits, lanes)} loop Check (Extract (Backends.Native.Replace (A, Lane, To_Lanes (B) (Lane)), Result_Lane) = (if Result_Lane = Lane then To_Lanes (B) (Lane) else To_Lanes (A) (Result_Lane)), \"{vector} independent native replace\" & Lane'Image & Result_Lane'Image); end loop;",
            "      end loop;",
        ]
        for name in ("Add_Wrap", "Subtract_Wrap", "Multiply_Wrap", "Add_Saturate", "Subtract_Saturate", "Bitwise_And", "Bitwise_Or", "Bitwise_Xor", "Min", "Max", "Interleave_Low", "Interleave_High", "Deinterleave_Even", "Deinterleave_Odd"):
            lines.append(f"      Check (Same (Backends.Native.{name} (A, B), {name} (A, B)), \"{vector} {name}\");")
        if bits == 64:
            lines.append(
                f"      Check (Backends.Native.To_Lanes (Backends.Native.Multiply_Wrap (Multiply_Edge_Left, Multiply_Edge_Right)) = Multiply_Edge_Expected, \"{vector} independent 32-bit partial-product boundaries\");"
            )
        if bits >= 32:
            lines.append(
                f"      Check (Backends.Native.To_Lanes (Backends.Native.Add_Saturate (Saturation_Left, Saturation_Right)) = Saturating_Add_Expected and then Backends.Native.To_Lanes (Backends.Native.Subtract_Saturate (Saturation_Left, Saturation_Right)) = Saturating_Subtract_Expected, \"{vector} independent fixed saturation boundaries\");"
            )
        if vector == "I64x2":
            lines.append(
                "      Check (Backends.Native.To_Lanes (Backends.Native.Add_Saturate (Saturation_Left_2, Saturation_Right_2)) = Saturating_Add_Expected_2 and then Backends.Native.To_Lanes (Backends.Native.Subtract_Saturate (Saturation_Left_2, Saturation_Right_2)) = Saturating_Subtract_Expected_2, \"I64x2 opposite fixed saturation boundaries\");"
            )
        lines += [
            f"      Check (Same (Backends.Native.Bitwise_Not (A), Bitwise_Not (A)), \"{vector} not\");",
            f"      Check (Same (Backends.Native.Reverse_Lanes (A), Reverse_Lanes (A)), \"{vector} reverse\");",
            f"      Check (Same (Backends.Native.Permute_Lanes (A, Fixed_Map), Permute_Lanes (A, Fixed_Map)), \"{vector} native fixed lane permutation\");",
            f"      for Lane in {lane_index(bits, lanes)} loop Check (Extract (Permute_Lanes (A, Fixed_Map), Lane) = Extract (A, Fixed_Selectors (Lane)), \"{vector} independent fixed lane permutation\" & Lane'Image); end loop;",
            f"      Check (Same (Permute_Lanes (A, Broadcast_Map), Splat (Extract (A, {lanes - 1}))) and then Same (Backends.Native.Permute_Lanes (A, Broadcast_Map), Splat (Extract (A, {lanes - 1}))), \"{vector} repeated-selector broadcast\");",
            f"      Check (Same (Permute_Lanes (A, Default_Map), Splat (Extract (A, 0))) and then Same (Backends.Native.Permute_Lanes (A, Default_Map), Splat (Extract (A, 0))), \"{vector} default lane map\");",
            f"      Check (Same (Backends.Native.Permute_Lanes (A, B, Fixed_Two_Source_Map), Permute_Lanes (A, B, Fixed_Two_Source_Map)), \"{vector} native fixed two-source lane permutation\");",
            f"      for Lane in {lane_index(bits, lanes)} loop Check (Extract (Permute_Lanes (A, B, Fixed_Two_Source_Map), Lane) = Extract ((if Lane mod 2 = 0 then A else B), {lane_index(bits, lanes)} ((Lane * 3 + 1) mod {lanes})), \"{vector} independent fixed two-source lane permutation\" & Lane'Image); end loop;",
            f"      Check (Same (Permute_Lanes (A, B, Default_Two_Source_Map), Splat (Extract (A, 0))) and then Same (Backends.Native.Permute_Lanes (A, B, Default_Two_Source_Map), Splat (Extract (A, 0))), \"{vector} default two-source lane map\");",
            f"      for Shift in Natural range 0 .. {bits + 2} loop",
            f"         Check (Same (Backends.Native.Shift_Left_Logical (A, Shift), Shift_Left_Logical (A, Shift)), \"{vector} shl\" & Shift'Image);",
            f"         Check (Same (Backends.Native.Shift_Right_Logical (A, Shift), Shift_Right_Logical (A, Shift)), \"{vector} shr\" & Shift'Image);",
        ]
        if signed:
            if vector == "I64x2":
                lines.append("         Check (Same (Shift_Right_Arithmetic (A, Shift), Reference_Shift_Right_Arithmetic_I64x2 (A, Shift)) and then Same (Backends.Native.Shift_Right_Arithmetic (A, Shift), Reference_Shift_Right_Arithmetic_I64x2 (A, Shift)), \"I64x2 independent arithmetic shift\" & Shift'Image);")
            else:
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
            f"      for Slide in Natural range 0 .. {lanes + 2} loop",
            f"         Check (Same (Backends.Native.Slide_Lanes_Toward_Low (A, Slide), Slide_Lanes_Toward_Low (A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (A, Slide), Slide_Lanes_Toward_High (A, Slide)), \"{vector} native lane slides\" & Slide'Image);",
            f"         for Lane in {lane_index(bits, lanes)} loop",
            f"            Check (Extract (Slide_Lanes_Toward_Low (A, Slide), Lane) = (if Slide < {lanes} and then Lane < {lanes} - Slide then Extract (A, {lane_index(bits, lanes)} (Lane + Slide)) else 0), \"{vector} independent slide toward low\" & Slide'Image & Lane'Image);",
            f"            Check (Extract (Slide_Lanes_Toward_High (A, Slide), Lane) = (if Slide < {lanes} and then Lane >= Slide then Extract (A, {lane_index(bits, lanes)} (Lane - Slide)) else 0), \"{vector} independent slide toward high\" & Slide'Image & Lane'Image);",
            "         end loop;",
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
            f"         Check (First_True ({mask}'(Mask_From_Bit_Mask ({mask_storage} (Pattern)))) = Reference_First_True (Pattern, {lanes}) and then Last_True ({mask}'(Mask_From_Bit_Mask ({mask_storage} (Pattern)))) = Reference_Last_True (Pattern, {lanes}), \"{vector} scalar mask positions\" & Pattern'Image);",
            f"         Check (To_Bit_Mask (Mask_Not ({mask}'(Mask_From_Bit_Mask ({mask_storage} (Pattern))))) = {mask_storage} (2 ** {lanes} - 1 - Pattern), \"{vector} scalar mask not\" & Pattern'Image);",
            f"         Check (To_Bit_Mask (Mask_And ({mask}'(Mask_From_Bit_Mask ({mask_storage} (Pattern))), Mask_From_Bit_Mask ({mask_storage} (2 ** {lanes} - 1 - Pattern)))) = 0 and then To_Bit_Mask (Mask_Or ({mask}'(Mask_From_Bit_Mask ({mask_storage} (Pattern))), Mask_From_Bit_Mask ({mask_storage} (2 ** {lanes} - 1 - Pattern)))) = {mask_storage} (2 ** {lanes} - 1) and then To_Bit_Mask (Mask_Xor ({mask}'(Mask_From_Bit_Mask ({mask_storage} (Pattern))), Mask_From_Bit_Mask ({mask_storage} (2 ** {lanes} - 1 - Pattern)))) = {mask_storage} (2 ** {lanes} - 1), \"{vector} scalar mask algebra\" & Pattern'Image);",
            f"         Check (Backends.Native.Any_True ({mask}'(Backends.Native.Mask_From_Bit_Mask ({mask_storage} (Pattern)))) = (Pattern /= 0) and then Backends.Native.None_True ({mask}'(Backends.Native.Mask_From_Bit_Mask ({mask_storage} (Pattern)))) = (Pattern = 0) and then Backends.Native.All_True ({mask}'(Backends.Native.Mask_From_Bit_Mask ({mask_storage} (Pattern)))) = (Pattern = 2 ** {lanes} - 1) and then Backends.Native.Population_Count ({mask}'(Backends.Native.Mask_From_Bit_Mask ({mask_storage} (Pattern)))) = Reference_Popcount (Pattern), \"{vector} native mask reductions\" & Pattern'Image);",
            f"         Check (Backends.Native.First_True ({mask}'(Backends.Native.Mask_From_Bit_Mask ({mask_storage} (Pattern)))) = Reference_First_True (Pattern, {lanes}) and then Backends.Native.Last_True ({mask}'(Backends.Native.Mask_From_Bit_Mask ({mask_storage} (Pattern)))) = Reference_Last_True (Pattern, {lanes}), \"{vector} native mask positions\" & Pattern'Image);",
            f"         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_Not ({mask}'(Backends.Native.Mask_From_Bit_Mask ({mask_storage} (Pattern))))) = {mask_storage} (2 ** {lanes} - 1 - Pattern), \"{vector} native mask not\" & Pattern'Image);",
            f"         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_And ({mask}'(Backends.Native.Mask_From_Bit_Mask ({mask_storage} (Pattern))), Backends.Native.Mask_From_Bit_Mask ({mask_storage} (2 ** {lanes} - 1 - Pattern)))) = 0 and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Or ({mask}'(Backends.Native.Mask_From_Bit_Mask ({mask_storage} (Pattern))), Backends.Native.Mask_From_Bit_Mask ({mask_storage} (2 ** {lanes} - 1 - Pattern)))) = {mask_storage} (2 ** {lanes} - 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Xor ({mask}'(Backends.Native.Mask_From_Bit_Mask ({mask_storage} (Pattern))), Backends.Native.Mask_From_Bit_Mask ({mask_storage} (2 ** {lanes} - 1 - Pattern)))) = {mask_storage} (2 ** {lanes} - 1), \"{vector} native mask algebra\" & Pattern'Image);",
            f"         for Lane in {lane_index(bits, lanes)} loop Check (Backends.Native.Test ({mask}'(Backends.Native.Mask_From_Bit_Mask ({mask_storage} (Pattern))), Lane) = ((Pattern / 2 ** Lane) mod 2 = 1), \"{vector} independent native mask lane\" & Pattern'Image & Lane'Image); end loop;",
            f"         Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask ({mask_storage} (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask ({mask_storage} (Pattern)), A, B)), \"{vector} exhaustive select\" & Pattern'Image);",
            f"         Check (Same (Compress (A, Mask_From_Bit_Mask ({mask_storage} (Pattern))), Reference_Compress_{vector} (A, Mask_From_Bit_Mask ({mask_storage} (Pattern)))) and then Same (Backends.Native.Compress (A, Backends.Native.Mask_From_Bit_Mask ({mask_storage} (Pattern))), Reference_Compress_{vector} (A, Mask_From_Bit_Mask ({mask_storage} (Pattern)))), \"{vector} exhaustive compress\" & Pattern'Image);",
            f"         Check (Same (Expand (A, Mask_From_Bit_Mask ({mask_storage} (Pattern))), Reference_Expand_{vector} (A, Mask_From_Bit_Mask ({mask_storage} (Pattern)))) and then Same (Backends.Native.Expand (A, Backends.Native.Mask_From_Bit_Mask ({mask_storage} (Pattern))), Reference_Expand_{vector} (A, Mask_From_Bit_Mask ({mask_storage} (Pattern)))), \"{vector} exhaustive expand\" & Pattern'Image);",
            f"         for Lane in {lane_index(bits, lanes)} loop Check (Extract (Select_Value (Mask_From_Bit_Mask ({mask_storage} (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)) and then Backends.Native.Extract (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask ({mask_storage} (Pattern)), A, B), Lane) = (if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane)), \"{vector} independent scalar and native select\" & Pattern'Image & Lane'Image); end loop;",
            "      end loop;",
            f"      Check (Backends.Native.To_Bit_Mask ({mask}'(Backends.Native.Mask_From_Bit_Mask ({mask_storage}'Last))) = {mask_storage} (2 ** {lanes} - 1), \"{vector} native masks unused storage bits\");",
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
            f"         for Lane in {lane_index(bits, lanes)} loop Check (Extract (Backends.Native.Load_Partial (Data, 2, N), Lane) = (if Lane < N then Extract (B, Lane) else 0), \"{vector} independent partial load\" & N'Image & Lane'Image); end loop;",
            "         declare",
            f"            Exact : {arr} (1 .. N) := [others => 0];",
            "         begin",
            f"            for Lane in {lane_index(bits, lanes)} loop Check (Extract (Backends.Native.Load_Partial (Exact, 1, N), Lane) = 0, \"{vector} exact-extent partial load\" & N'Image & Lane'Image); end loop;",
            f"            Backends.Native.Store_Partial (Exact, 1, N, B);",
            "         end;",
            "      end loop;",
            f"      for Lane in {lane_index(bits, lanes)} loop Check (Extract (Backends.Native.Load_Partial (Maximum_Index_Data, Natural'Last, 0), Lane) = 0, \"{vector} maximum-index zero-count partial load\" & Lane'Image); end loop;",
            f"      Backends.Native.Store_Partial (Maximum_Index_Data, Natural'Last, 0, A);",
            f"      Check (Maximum_Index_Data (Natural'Last) = {scalar} (1), \"{vector} maximum-index zero-count partial store\");",
            "      for Iteration in 1 .. 250 loop",
            "         declare",
            f"            R_Lanes : constant {vals} := Random_{vector}_Lanes;",
            f"            R_A : constant {vector} := From_Lanes (R_Lanes);",
            f"            R_B : constant {vector} := From_Lanes (Random_{vector}_Lanes);",
            f"            Shift : constant Natural := Natural (Next_U64 mod {bits + 3});",
            f"            Tail : constant {count} := {count} (Next_U64 mod {lanes + 1});",
            f"            Slide : constant Natural := Natural (Next_U64 mod {lanes + 3});",
            f"            Pattern : constant {mask_storage} := {mask_storage} (Next_U64 mod 2 ** {lanes});",
            f"            R_Selectors : constant {lane_selectors(bits, lanes)} := Random_{vector}_Selectors;",
            f"            R_Map : constant {lane_map(bits, lanes)} := Make_Lane_Map (R_Selectors);",
            f"            R_Two_Source_Map : constant {two_source_lane_map(bits, lanes)} := Make_Two_Source_Lane_Map ([for Lane in {lane_index(bits, lanes)} => (if (Iteration + Lane) mod 2 = 0 then Select_Left_Lane ({lane_index(bits, lanes)} ((Iteration * 3 + Lane * 5) mod {lanes})) else Select_Right_Lane ({lane_index(bits, lanes)} ((Iteration * 3 + Lane * 5) mod {lanes})))]);",
            "         begin",
            f"            Check (To_Lanes (Backends.Native.From_Lanes (R_Lanes)) = R_Lanes and then Backends.Native.To_Lanes (R_A) = R_Lanes, \"{vector} randomized independent native lane construction\");",
            f"            for Lane in {lane_index(bits, lanes)} loop Check (Extract (Backends.Native.Splat (R_Lanes (0)), Lane) = R_Lanes (0), \"{vector} randomized independent native splat\" & Lane'Image); end loop;",
            f"            Check (Same (Backends.Native.Add_Wrap (R_A, R_B), Add_Wrap (R_A, R_B)) and then Same (Backends.Native.Subtract_Wrap (R_A, R_B), Subtract_Wrap (R_A, R_B)) and then Same (Backends.Native.Multiply_Wrap (R_A, R_B), Multiply_Wrap (R_A, R_B)), \"{vector} randomized arithmetic\");",
            f"            Check (Same (Backends.Native.Add_Saturate (R_A, R_B), Add_Saturate (R_A, R_B)) and then Same (Backends.Native.Subtract_Saturate (R_A, R_B), Subtract_Saturate (R_A, R_B)), \"{vector} randomized native saturation\");",
            f"            Check (Same (Backends.Native.Bitwise_And (R_A, R_B), Bitwise_And (R_A, R_B)) and then Same (Backends.Native.Bitwise_Or (R_A, R_B), Bitwise_Or (R_A, R_B)) and then Same (Backends.Native.Bitwise_Xor (R_A, R_B), Bitwise_Xor (R_A, R_B)) and then Same (Backends.Native.Bitwise_Not (R_A), Bitwise_Not (R_A)), \"{vector} randomized native bitwise\");",
            f"            Check (Same (Backends.Native.Min (R_A, R_B), Min (R_A, R_B)) and then Same (Backends.Native.Max (R_A, R_B), Max (R_A, R_B)), \"{vector} randomized native min/max\");",
            f"            Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (R_A, R_B)), \"{vector} randomized native comparisons\");",
            f"            Check (Same (Backends.Native.Shift_Left_Logical (R_A, Shift), Shift_Left_Logical (R_A, Shift)) and then Same (Backends.Native.Shift_Right_Logical (R_A, Shift), Shift_Right_Logical (R_A, Shift)), \"{vector} randomized native logical shifts\");",
            *(([
                "            Check (Same (Shift_Right_Arithmetic (R_A, Shift), Reference_Shift_Right_Arithmetic_I64x2 (R_A, Shift)) and then Same (Backends.Native.Shift_Right_Arithmetic (R_A, Shift), Reference_Shift_Right_Arithmetic_I64x2 (R_A, Shift)), \"I64x2 randomized independent arithmetic shift\");"
                if vector == "I64x2" else
                f"            Check (Same (Backends.Native.Shift_Right_Arithmetic (R_A, Shift), Shift_Right_Arithmetic (R_A, Shift)), \"{vector} randomized native arithmetic shift\");"
            ] if signed else [])),
            f"            Check (Same (Backends.Native.Reverse_Lanes (R_A), Reverse_Lanes (R_A)) and then Same (Backends.Native.Interleave_Low (R_A, R_B), Interleave_Low (R_A, R_B)) and then Same (Backends.Native.Interleave_High (R_A, R_B), Interleave_High (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Even (R_A, R_B), Deinterleave_Even (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Odd (R_A, R_B), Deinterleave_Odd (R_A, R_B)), \"{vector} randomized native permutations\");",
            f"            Check (Same (Backends.Native.Permute_Lanes (R_A, R_Map), Permute_Lanes (R_A, R_Map)), \"{vector} randomized native lane permutation\");",
            f"            Check (Same (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Permute_Lanes (R_A, R_B, R_Two_Source_Map)), \"{vector} randomized native two-source lane permutation\");",
            f"            Check (Same (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Slide_Lanes_Toward_Low (R_A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Slide_Lanes_Toward_High (R_A, Slide)), \"{vector} randomized native lane slides\");",
            f"            Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)), \"{vector} randomized native select\");",
            f"            Check (Same (Backends.Native.Compress (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Compress_{vector} (R_A, Mask_From_Bit_Mask (Pattern))) and then Same (Backends.Native.Expand (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Expand_{vector} (R_A, Mask_From_Bit_Mask (Pattern))), \"{vector} randomized native compression\");",
            f"            Check (Backends.Native.Reduce_Add_Wrap (R_A) = Reference_Reduce_Add_{vector} (R_A) and then Backends.Native.Reduce_Min (R_A) = Reference_Reduce_Min_{vector} (R_A) and then Backends.Native.Reduce_Max (R_A) = Reference_Reduce_Max_{vector} (R_A), \"{vector} randomized native reductions\");",
            f"            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Unaligned (Data, 1, R_A); Store_Unaligned (Reference, 1, R_A);",
            f"            Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), R_A), \"{vector} randomized native full memory\");",
            f"            Data := [others => 0]; Reference := [others => 0]; Backends.Native.Store_Partial (Data, 2, Tail, R_B); Store_Partial (Reference, 2, Tail, R_B);",
            f"            Check (Data = Reference, \"{vector} randomized native partial store\");",
            f"            for Lane in {lane_index(bits, lanes)} loop Check (Extract (Backends.Native.Load_Partial (Data, 2, Tail), Lane) = (if Lane < Tail then Extract (R_B, Lane) else 0), \"{vector} randomized independent partial load\" & Lane'Image); end loop;",
            f"            for Lane in {lane_index(bits, lanes)} loop",
            f"               Check (Extract (Permute_Lanes (R_A, R_Map), Lane) = R_Lanes (R_Selectors (Lane)), \"{vector} randomized independent lane permutation\" & Lane'Image);",
            f"               Check (Extract (Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane) = Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), {lane_index(bits, lanes)} ((Iteration * 3 + Lane * 5) mod {lanes})), \"{vector} varied independent two-source lane permutation\" & Lane'Image);",
            f"               Check (Backends.Native.Extract (R_A, Lane) = R_Lanes (Lane) and then Same (Backends.Native.Replace (R_A, Lane, Extract (R_B, Lane)), Replace (R_A, Lane, Extract (R_B, Lane))), \"{vector} randomized native lane access\" & Lane'Image);",
            f"               Check (Extract (Add_Wrap (R_A, R_B), Lane) = {add_oracle}, \"{vector} independent add oracle\" & Lane'Image);",
            f"               Check (Extract (Subtract_Wrap (R_A, R_B), Lane) = {sub_oracle}, \"{vector} independent subtract oracle\" & Lane'Image);",
            f"               Check (Extract (Multiply_Wrap (R_A, R_B), Lane) = {mul_oracle} and then Backends.Native.Extract (Backends.Native.Multiply_Wrap (R_A, R_B), Lane) = {mul_oracle}, \"{vector} independent scalar and native multiply oracle\" & Lane'Image);",
            f"               Check (Extract (Add_Saturate (R_A, R_B), Lane) = Reference_Add_Saturate_{vector} (Extract (R_A, Lane), Extract (R_B, Lane)) and then Backends.Native.Extract (Backends.Native.Add_Saturate (R_A, R_B), Lane) = Reference_Add_Saturate_{vector} (Extract (R_A, Lane), Extract (R_B, Lane)) and then Extract (Subtract_Saturate (R_A, R_B), Lane) = Reference_Subtract_Saturate_{vector} (Extract (R_A, Lane), Extract (R_B, Lane)) and then Backends.Native.Extract (Backends.Native.Subtract_Saturate (R_A, R_B), Lane) = Reference_Subtract_Saturate_{vector} (Extract (R_A, Lane), Extract (R_B, Lane)), \"{vector} independent scalar and native saturation oracle\" & Lane'Image);",
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
        special_bits = {
            "F32x4": [
                ["16#8000_0000#", "16#0000_0001#", "16#7F80_0000#", "16#7FC0_0001#"],
                ["16#7F80_0001#", "16#FF80_0000#", "16#FFC0_0021#", "16#8000_0001#"],
            ],
            "F64x2": [
                ["16#8000_0000_0000_0000#", "16#0000_0000_0000_0001#"],
                ["16#7FF0_0000_0000_0000#", "16#7FF8_0000_0000_0001#"],
                ["16#7FF0_0000_0000_0001#", "16#FFF0_0000_0000_0000#"],
            ],
        }[vector]
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
            f"   function Random_{vector}_Selectors return {lane_selectors(bits, lanes)} is",
            f"      Result : {lane_selectors(bits, lanes)};",
            "   begin",
            f"      for Lane in {lane_index(bits, lanes)} loop Result (Lane) := {lane_index(bits, lanes)} (Next_U64 mod {lanes}); end loop;",
            "      return Result;",
            f"   end Random_{vector}_Selectors;",
            f"   function Bits_{vector} is new Ada.Unchecked_Conversion ({scalar}, {uint});",
            f"   function Value_From_Bits_{vector} is new Ada.Unchecked_Conversion ({uint}, {scalar});",
            f"   function Same (Left, Right : {vector}) return Boolean is",
            f"      L : constant {vals} := To_Lanes (Left);",
            f"      R : constant {vals} := To_Lanes (Right);",
            "   begin",
            f"      for Lane in {lane_index(bits, lanes)} loop",
            f"         if Bits_{vector} (L (Lane)) /= Bits_{vector} (R (Lane)) then return False; end if;",
            "      end loop;",
            "      return True;",
            "   end Same;",
            f"   function Reference_Compress_{vector} (Value : {vector}; Mask : {mask}) return {vector} is",
            f"      Result : {vector} := Zero;",
            "      Result_Lane : Natural := 0;",
            "   begin",
            f"      for Source_Lane in {lane_index(bits, lanes)} loop",
            "         if Test (Mask, Source_Lane) then",
            f"            Result := Replace (Result, {lane_index(bits, lanes)} (Result_Lane), Extract (Value, Source_Lane));",
            "            Result_Lane := Result_Lane + 1;",
            "         end if;",
            "      end loop;",
            "      return Result;",
            f"   end Reference_Compress_{vector};",
            f"   function Reference_Expand_{vector} (Value : {vector}; Mask : {mask}) return {vector} is",
            f"      Result : {vector} := Zero;",
            "      Source_Lane : Natural := 0;",
            "   begin",
            f"      for Result_Lane in {lane_index(bits, lanes)} loop",
            "         if Test (Mask, Result_Lane) then",
            f"            Result := Replace (Result, Result_Lane, Extract (Value, {lane_index(bits, lanes)} (Source_Lane)));",
            "            Source_Lane := Source_Lane + 1;",
            "         end if;",
            "      end loop;",
            "      return Result;",
            f"   end Reference_Expand_{vector};",
            f"   function Reference_Reduce_Add_{vector} (Value : {vector}) return {scalar} is",
            f"      Result : {scalar} := 0.0;",
            "   begin",
            f"      for Lane in {lane_index(bits, lanes)} loop Result := Result + Extract (Value, Lane); end loop;",
            "      return Result;",
            f"   end Reference_Reduce_Add_{vector};",
            f"   function Reference_Reduce_Min_{vector} (Value : {vector}) return {scalar} is",
            f"      Result : {scalar} := Extract (Value, 0);",
            "   begin",
            f"      for Lane in {lane_index(bits, lanes)} range 1 .. {lanes - 1} loop if Extract (Value, Lane) < Result then Result := Extract (Value, Lane); end if; end loop;",
            "      return Result;",
            f"   end Reference_Reduce_Min_{vector};",
            f"   function Reference_Reduce_Max_{vector} (Value : {vector}) return {scalar} is",
            f"      Result : {scalar} := Extract (Value, 0);",
            "   begin",
            f"      for Lane in {lane_index(bits, lanes)} range 1 .. {lanes - 1} loop if Extract (Value, Lane) > Result then Result := Extract (Value, Lane); end if; end loop;",
            "      return Result;",
            f"   end Reference_Reduce_Max_{vector};",
            f"   procedure Test_{vector} is",
            f"      A : constant {vector} := From_Lanes ([{agg_a}]);", f"      B : constant {vector} := From_Lanes ([{agg_b}]);",
            f"      Fixed_Selectors : constant {lane_selectors(bits, lanes)} := [{', '.join(str((n * 3 + 1) % lanes) for n in range(lanes))}];",
            f"      Fixed_Map : constant {lane_map(bits, lanes)} := Make_Lane_Map (Fixed_Selectors);",
            f"      Broadcast_Map : constant {lane_map(bits, lanes)} := Make_Lane_Map ([others => {lanes - 1}]);",
            f"      Default_Map : {lane_map(bits, lanes)};",
            f"      Fixed_Two_Source_Map : constant {two_source_lane_map(bits, lanes)} := Make_Two_Source_Lane_Map ([for Lane in {lane_index(bits, lanes)} => (if Lane mod 2 = 0 then Select_Left_Lane ({lane_index(bits, lanes)} ((Lane * 3 + 1) mod {lanes})) else Select_Right_Lane ({lane_index(bits, lanes)} ((Lane * 3 + 1) mod {lanes})))]);",
            f"      Default_Two_Source_Map : {two_source_lane_map(bits, lanes)};",
            f"      Data, Reference : {arr} (0 .. {lanes + 5}) := [others => 0.0];",
            f"      Aligned_Data : {arr} (0 .. {lanes - 1}) := [others => 0.0] with Alignment => 16;",
            f"      Maximum_Index_Data : {arr} (Natural'Last .. Natural'Last) := [others => 1.0];",
            *[
                f"      Special_Lanes_{group_index} : constant {vals} := [{', '.join(f'Value_From_Bits_{vector} ({raw})' for raw in group)}];"
                for group_index, group in enumerate(special_bits, 1)
            ],
            "   begin",
            f"      Check (Same (A, From_Lanes (To_Lanes (A))), \"{vector} scalar lane roundtrip\");",
            f"      for Lane in {lane_index(bits, lanes)} loop Check (Bits_{vector} (Extract ({vector}'(Backends.Native.Zero), Lane)) = 0 and then Bits_{vector} (Extract (Backends.Native.Splat (To_Lanes (A) (0)), Lane)) = Bits_{vector} (To_Lanes (A) (0)), \"{vector} independent native construction\" & Lane'Image); end loop;",
            f"      for Lane in {lane_index(bits, lanes)} loop Check (Bits_{vector} (Extract (Backends.Native.From_Lanes (To_Lanes (A)), Lane)) = Bits_{vector} (To_Lanes (A) (Lane)) and then Bits_{vector} (Backends.Native.To_Lanes (A) (Lane)) = Bits_{vector} (To_Lanes (A) (Lane)), \"{vector} independent native lane construction\" & Lane'Image); end loop;",
            f"      for Lane in {lane_index(bits, lanes)} loop",
            f"         Check (Bits_{vector} (Extract (A, Lane)) = Bits_{vector} (To_Lanes (A) (Lane)), \"{vector} scalar extract\" & Lane'Image);",
            f"         Check (Bits_{vector} (Backends.Native.Extract (A, Lane)) = Bits_{vector} (To_Lanes (A) (Lane)), \"{vector} independent native extract\" & Lane'Image);",
            f"         for Result_Lane in {lane_index(bits, lanes)} loop Check (Bits_{vector} (Extract (Backends.Native.Replace (A, Lane, To_Lanes (B) (Lane)), Result_Lane)) = Bits_{vector} ((if Result_Lane = Lane then To_Lanes (B) (Lane) else To_Lanes (A) (Result_Lane))), \"{vector} independent native replace\" & Lane'Image & Result_Lane'Image); end loop;",
            "      end loop;",
        ]
        for name in ("Add", "Subtract", "Multiply", "Divide", "Min_Number", "Max_Number", "Interleave_Low", "Interleave_High", "Deinterleave_Even", "Deinterleave_Odd"):
            lines.append(f"      Check (Same (Backends.Native.{name} (A, B), {name} (A, B)), \"{vector} {name}\");")
        lines += [
            f"      Check (Same (Backends.Native.Reverse_Lanes (A), Reverse_Lanes (A)), \"{vector} reverse\");",
            f"      Check (Same (Backends.Native.Permute_Lanes (A, Fixed_Map), Permute_Lanes (A, Fixed_Map)), \"{vector} native fixed lane permutation\");",
            f"      for Lane in {lane_index(bits, lanes)} loop Check (Bits_{vector} (Extract (Permute_Lanes (A, Fixed_Map), Lane)) = Bits_{vector} (Extract (A, Fixed_Selectors (Lane))), \"{vector} independent fixed lane permutation\" & Lane'Image); end loop;",
            f"      Check (Same (Permute_Lanes (A, Broadcast_Map), Splat (Extract (A, {lanes - 1}))) and then Same (Backends.Native.Permute_Lanes (A, Broadcast_Map), Splat (Extract (A, {lanes - 1}))), \"{vector} repeated-selector broadcast\");",
            f"      Check (Same (Permute_Lanes (A, Default_Map), Splat (Extract (A, 0))) and then Same (Backends.Native.Permute_Lanes (A, Default_Map), Splat (Extract (A, 0))), \"{vector} default lane map\");",
            f"      Check (Same (Backends.Native.Permute_Lanes (A, B, Fixed_Two_Source_Map), Permute_Lanes (A, B, Fixed_Two_Source_Map)), \"{vector} native fixed two-source lane permutation\");",
            f"      for Lane in {lane_index(bits, lanes)} loop Check (Bits_{vector} (Extract (Permute_Lanes (A, B, Fixed_Two_Source_Map), Lane)) = Bits_{vector} (Extract ((if Lane mod 2 = 0 then A else B), {lane_index(bits, lanes)} ((Lane * 3 + 1) mod {lanes}))), \"{vector} independent fixed two-source lane permutation\" & Lane'Image); end loop;",
            f"      Check (Same (Permute_Lanes (A, B, Default_Two_Source_Map), Splat (Extract (A, 0))) and then Same (Backends.Native.Permute_Lanes (A, B, Default_Two_Source_Map), Splat (Extract (A, 0))), \"{vector} default two-source lane map\");",
        ]
        lines += [
            f"      for Slide in Natural range 0 .. {lanes + 2} loop",
            f"         Check (Same (Backends.Native.Slide_Lanes_Toward_Low (A, Slide), Slide_Lanes_Toward_Low (A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (A, Slide), Slide_Lanes_Toward_High (A, Slide)), \"{vector} native lane slides\" & Slide'Image);",
            f"         for Lane in {lane_index(bits, lanes)} loop",
            f"            Check (Bits_{vector} (Extract (Slide_Lanes_Toward_Low (A, Slide), Lane)) = (if Slide < {lanes} and then Lane < {lanes} - Slide then Bits_{vector} (Extract (A, {lane_index(bits, lanes)} (Lane + Slide))) else 0), \"{vector} independent slide toward low\" & Slide'Image & Lane'Image);",
            f"            Check (Bits_{vector} (Extract (Slide_Lanes_Toward_High (A, Slide), Lane)) = (if Slide < {lanes} and then Lane >= Slide then Bits_{vector} (Extract (A, {lane_index(bits, lanes)} (Lane - Slide))) else 0), \"{vector} independent slide toward high\" & Slide'Image & Lane'Image);",
            "         end loop;",
            "      end loop;",
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
            f"         Check (First_True ({mask}'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_First_True (Pattern, {lanes}) and then Last_True ({mask}'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Last_True (Pattern, {lanes}), \"{vector} scalar mask positions\" & Pattern'Image);",
            f"         Check (To_Bit_Mask (Mask_Not ({mask}'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** {lanes} - 1 - Pattern), \"{vector} scalar mask not\" & Pattern'Image);",
            f"         Check (To_Bit_Mask (Mask_And ({mask}'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** {lanes} - 1 - Pattern)))) = 0 and then To_Bit_Mask (Mask_Or ({mask}'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** {lanes} - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** {lanes} - 1) and then To_Bit_Mask (Mask_Xor ({mask}'(Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** {lanes} - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** {lanes} - 1), \"{vector} scalar mask algebra\" & Pattern'Image);",
            f"         Check (Backends.Native.Any_True ({mask}'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern /= 0) and then Backends.Native.None_True ({mask}'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 0) and then Backends.Native.All_True ({mask}'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = (Pattern = 2 ** {lanes} - 1) and then Backends.Native.Population_Count ({mask}'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Popcount (Pattern), \"{vector} native mask reductions\" & Pattern'Image);",
            f"         Check (Backends.Native.First_True ({mask}'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_First_True (Pattern, {lanes}) and then Backends.Native.Last_True ({mask}'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) = Reference_Last_True (Pattern, {lanes}), \"{vector} native mask positions\" & Pattern'Image);",
            f"         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_Not ({mask}'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))))) = Interfaces.Unsigned_8 (2 ** {lanes} - 1 - Pattern), \"{vector} native mask not\" & Pattern'Image);",
            f"         Check (Backends.Native.To_Bit_Mask (Backends.Native.Mask_And ({mask}'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** {lanes} - 1 - Pattern)))) = 0 and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Or ({mask}'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** {lanes} - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** {lanes} - 1) and then Backends.Native.To_Bit_Mask (Backends.Native.Mask_Xor ({mask}'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (2 ** {lanes} - 1 - Pattern)))) = Interfaces.Unsigned_8 (2 ** {lanes} - 1), \"{vector} native mask algebra\" & Pattern'Image);",
            f"         for Lane in {lane_index(bits, lanes)} loop Check (Backends.Native.Test ({mask}'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Lane) = ((Pattern / 2 ** Lane) mod 2 = 1), \"{vector} independent native mask lane\" & Pattern'Image & Lane'Image); end loop;",
            f"         Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B)), \"{vector} exhaustive select\" & Pattern'Image);",
            f"         Check (Same (Compress (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_{vector} (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Compress (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Compress_{vector} (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), \"{vector} exhaustive compress\" & Pattern'Image);",
            f"         Check (Same (Expand (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_{vector} (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))) and then Same (Backends.Native.Expand (A, Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern))), Reference_Expand_{vector} (A, Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)))), \"{vector} exhaustive expand\" & Pattern'Image);",
            f"         for Lane in {lane_index(bits, lanes)} loop Check (Bits_{vector} (Extract (Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane)) = Bits_{vector} ((if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane))) and then Bits_{vector} (Backends.Native.Extract (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), A, B), Lane)) = Bits_{vector} ((if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (A, Lane) else Extract (B, Lane))), \"{vector} independent bitwise scalar and native select\" & Pattern'Image & Lane'Image); end loop;",
            "      end loop;",
            f"      Check (Backends.Native.To_Bit_Mask ({mask}'(Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8'Last))) = Interfaces.Unsigned_8 (2 ** {lanes} - 1), \"{vector} native masks unused storage bits\");",
            f"      Check (Bits_{vector} (Reduce_Add (A)) = Bits_{vector} (Reference_Reduce_Add_{vector} (A)) and then Bits_{vector} (Backends.Native.Reduce_Add (A)) = Bits_{vector} (Reference_Reduce_Add_{vector} (A)), \"{vector} independent reduce\");",
            f"      Check (Bits_{vector} (Reduce_Min_Number (B)) = Bits_{vector} (Reference_Reduce_Min_{vector} (B)) and then Bits_{vector} (Backends.Native.Reduce_Min_Number (B)) = Bits_{vector} (Reference_Reduce_Min_{vector} (B)) and then Bits_{vector} (Reduce_Max_Number (B)) = Bits_{vector} (Reference_Reduce_Max_{vector} (B)) and then Bits_{vector} (Backends.Native.Reduce_Max_Number (B)) = Bits_{vector} (Reference_Reduce_Max_{vector} (B)), \"{vector} independent min/max reductions\");",
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
            f"         for Lane in {lane_index(bits, lanes)} loop Check (Bits_{vector} (Extract (Backends.Native.Load_Partial (Data, 2, N), Lane)) = Bits_{vector} ((if Lane < N then Extract (B, Lane) else 0.0)), \"{vector} independent partial load\" & N'Image & Lane'Image); end loop;",
            "         declare",
            f"            Exact : {arr} (1 .. N) := [others => 0.0];",
            "         begin",
            f"            for Lane in {lane_index(bits, lanes)} loop Check (Bits_{vector} (Extract (Backends.Native.Load_Partial (Exact, 1, N), Lane)) = 0, \"{vector} exact-extent partial load\" & N'Image & Lane'Image); end loop;",
            f"            Backends.Native.Store_Partial (Exact, 1, N, B);",
            "         end;",
            "      end loop;",
            *[
                line
                for group_index, _ in enumerate(special_bits, 1)
                for line in [
                    f"      for N in {count} loop",
                    f"         Data := [others => Value_From_Bits_{vector} ({'16#7FC0_0055#' if vector == 'F32x4' else '16#7FF8_0000_0000_0055#'})];",
                    f"         for Lane in {lane_index(bits, lanes)} loop Data (2 + Lane) := Special_Lanes_{group_index} (Lane); end loop;",
                    f"         for Lane in {lane_index(bits, lanes)} loop Check (Bits_{vector} (Extract (Backends.Native.Load_Partial (Data, 2, N), Lane)) = (if Lane < N then Bits_{vector} (Special_Lanes_{group_index} (Lane)) else 0), \"{vector} special-bit partial load group {group_index}\" & N'Image & Lane'Image); end loop;",
                    f"         Data := [others => Value_From_Bits_{vector} ({'16#7FC0_0055#' if vector == 'F32x4' else '16#7FF8_0000_0000_0055#'})];",
                    f"         Backends.Native.Store_Partial (Data, 2, N, From_Lanes (Special_Lanes_{group_index}));",
                    f"         for Index in Data'Range loop Check (Bits_{vector} (Data (Index)) = (if Index in 2 .. 2 + N - 1 then Bits_{vector} (Special_Lanes_{group_index} ({lane_index(bits, lanes)} (Index - 2))) else {'16#7FC0_0055#' if vector == 'F32x4' else '16#7FF8_0000_0000_0055#'}), \"{vector} special-bit partial store group {group_index}\" & N'Image & Index'Image); end loop;",
                    "      end loop;",
                ]
            ],
            f"      for Lane in {lane_index(bits, lanes)} loop Check (Bits_{vector} (Extract (Backends.Native.Load_Partial (Maximum_Index_Data, Natural'Last, 0), Lane)) = 0, \"{vector} maximum-index zero-count partial load\" & Lane'Image); end loop;",
            f"      Backends.Native.Store_Partial (Maximum_Index_Data, Natural'Last, 0, A);",
            f"      Check (Bits_{vector} (Maximum_Index_Data (Natural'Last)) = Bits_{vector} (1.0), \"{vector} maximum-index zero-count partial store\");",
            "      for Iteration in 1 .. 250 loop",
            "         declare",
            f"            R_Lanes : constant {vals} := Random_{vector}_Lanes;",
            f"            R_A : constant {vector} := From_Lanes (R_Lanes);",
            f"            R_B : constant {vector} := From_Lanes (Random_{vector}_Lanes);",
            f"            Tail : constant {count} := {count} (Next_U64 mod {lanes + 1});",
            f"            Slide : constant Natural := Natural (Next_U64 mod {lanes + 3});",
            f"            Pattern : constant Interfaces.Unsigned_8 := Interfaces.Unsigned_8 (Next_U64 mod 2 ** {lanes});",
            f"            R_Selectors : constant {lane_selectors(bits, lanes)} := Random_{vector}_Selectors;",
            f"            R_Map : constant {lane_map(bits, lanes)} := Make_Lane_Map (R_Selectors);",
            f"            R_Two_Source_Map : constant {two_source_lane_map(bits, lanes)} := Make_Two_Source_Lane_Map ([for Lane in {lane_index(bits, lanes)} => (if (Iteration + Lane) mod 2 = 0 then Select_Left_Lane ({lane_index(bits, lanes)} ((Iteration * 3 + Lane * 5) mod {lanes})) else Select_Right_Lane ({lane_index(bits, lanes)} ((Iteration * 3 + Lane * 5) mod {lanes})))]);",
            "         begin",
            f"            for Lane in {lane_index(bits, lanes)} loop Check (Bits_{vector} (Extract (Backends.Native.From_Lanes (R_Lanes), Lane)) = Bits_{vector} (R_Lanes (Lane)) and then Bits_{vector} (Backends.Native.To_Lanes (R_A) (Lane)) = Bits_{vector} (R_Lanes (Lane)), \"{vector} randomized independent native lane construction\" & Lane'Image); end loop;",
            f"            for Lane in {lane_index(bits, lanes)} loop Check (Bits_{vector} (Extract (Backends.Native.Splat (R_Lanes (0)), Lane)) = Bits_{vector} (R_Lanes (0)), \"{vector} randomized independent native splat\" & Lane'Image); end loop;",
            f"            Check (Same (Backends.Native.Add (R_A, R_B), Add (R_A, R_B)) and then Same (Backends.Native.Subtract (R_A, R_B), Subtract (R_A, R_B)) and then Same (Backends.Native.Multiply (R_A, R_B), Multiply (R_A, R_B)) and then Same (Backends.Native.Divide (R_A, R_B), Divide (R_A, R_B)), \"{vector} randomized native arithmetic\");",
            f"            Check (Same (Backends.Native.Min_Number (R_A, R_B), Min_Number (R_A, R_B)) and then Same (Backends.Native.Max_Number (R_A, R_B), Max_Number (R_A, R_B)), \"{vector} randomized native min/max\");",
            f"            Check (Backends.Native.To_Bit_Mask (Backends.Native.Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Than (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Less_Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Less_Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Than (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Than (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Greater_Equal (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Greater_Equal (R_A, R_B)) and then Backends.Native.To_Bit_Mask (Backends.Native.Unordered (R_A, R_B)) = Flyology_SIMD.To_Bit_Mask (Unordered (R_A, R_B)), \"{vector} randomized native comparisons\");",
            f"            Check (Same (Backends.Native.Reverse_Lanes (R_A), Reverse_Lanes (R_A)) and then Same (Backends.Native.Interleave_Low (R_A, R_B), Interleave_Low (R_A, R_B)) and then Same (Backends.Native.Interleave_High (R_A, R_B), Interleave_High (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Even (R_A, R_B), Deinterleave_Even (R_A, R_B)) and then Same (Backends.Native.Deinterleave_Odd (R_A, R_B), Deinterleave_Odd (R_A, R_B)), \"{vector} randomized native permutations\");",
            f"            Check (Same (Backends.Native.Permute_Lanes (R_A, R_Map), Permute_Lanes (R_A, R_Map)), \"{vector} randomized native lane permutation\");",
            f"            Check (Same (Backends.Native.Permute_Lanes (R_A, R_B, R_Two_Source_Map), Permute_Lanes (R_A, R_B, R_Two_Source_Map)), \"{vector} randomized native two-source lane permutation\");",
            f"            Check (Same (Backends.Native.Slide_Lanes_Toward_Low (R_A, Slide), Slide_Lanes_Toward_Low (R_A, Slide)) and then Same (Backends.Native.Slide_Lanes_Toward_High (R_A, Slide), Slide_Lanes_Toward_High (R_A, Slide)), \"{vector} randomized native lane slides\");",
            f"            Check (Same (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Pattern), R_A, R_B), Select_Value (Mask_From_Bit_Mask (Pattern), R_A, R_B)), \"{vector} randomized native select\");",
            f"            Check (Same (Backends.Native.Compress (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Compress_{vector} (R_A, Mask_From_Bit_Mask (Pattern))) and then Same (Backends.Native.Expand (R_A, Backends.Native.Mask_From_Bit_Mask (Pattern)), Reference_Expand_{vector} (R_A, Mask_From_Bit_Mask (Pattern))), \"{vector} randomized native compression\");",
            f"            Check (Bits_{vector} (Backends.Native.Reduce_Add (R_A)) = Bits_{vector} (Reference_Reduce_Add_{vector} (R_A)) and then Bits_{vector} (Backends.Native.Reduce_Min_Number (R_A)) = Bits_{vector} (Reference_Reduce_Min_{vector} (R_A)) and then Bits_{vector} (Backends.Native.Reduce_Max_Number (R_A)) = Bits_{vector} (Reference_Reduce_Max_{vector} (R_A)), \"{vector} randomized native reductions\");",
            f"            Data := [others => 0.0]; Reference := [others => 0.0]; Backends.Native.Store_Unaligned (Data, 1, R_A); Store_Unaligned (Reference, 1, R_A);",
            f"            Check (Data = Reference and then Same (Backends.Native.Load_Unaligned (Data, 1), R_A), \"{vector} randomized native full memory\");",
            f"            Data := [others => 0.0]; Reference := [others => 0.0]; Backends.Native.Store_Partial (Data, 2, Tail, R_B); Store_Partial (Reference, 2, Tail, R_B);",
            f"            Check (Data = Reference, \"{vector} randomized native partial store\");",
            f"            for Lane in {lane_index(bits, lanes)} loop Check (Bits_{vector} (Extract (Backends.Native.Load_Partial (Data, 2, Tail), Lane)) = Bits_{vector} ((if Lane < Tail then Extract (R_B, Lane) else 0.0)), \"{vector} randomized independent partial load\" & Lane'Image); end loop;",
            f"            for Lane in {lane_index(bits, lanes)} loop",
            f"               Check (Bits_{vector} (Extract (Permute_Lanes (R_A, R_Map), Lane)) = Bits_{vector} (R_Lanes (R_Selectors (Lane))), \"{vector} randomized independent lane permutation\" & Lane'Image);",
            f"               Check (Bits_{vector} (Extract (Permute_Lanes (R_A, R_B, R_Two_Source_Map), Lane)) = Bits_{vector} (Extract ((if (Iteration + Lane) mod 2 = 0 then R_A else R_B), {lane_index(bits, lanes)} ((Iteration * 3 + Lane * 5) mod {lanes}))), \"{vector} varied independent two-source lane permutation\" & Lane'Image);",
            f"               Check (Bits_{vector} (Backends.Native.Extract (R_A, Lane)) = Bits_{vector} (R_Lanes (Lane)) and then Same (Backends.Native.Replace (R_A, Lane, Extract (R_B, Lane)), Replace (R_A, Lane, Extract (R_B, Lane))), \"{vector} randomized native lane access\" & Lane'Image);",
            f"               Check (Bits_{vector} (Extract (Add (R_A, R_B), Lane)) = Bits_{vector} (Extract (R_A, Lane) + Extract (R_B, Lane)) and then Bits_{vector} (Extract (Subtract (R_A, R_B), Lane)) = Bits_{vector} (Extract (R_A, Lane) - Extract (R_B, Lane)) and then Bits_{vector} (Extract (Multiply (R_A, R_B), Lane)) = Bits_{vector} (Extract (R_A, Lane) * Extract (R_B, Lane)), \"{vector} randomized independent arithmetic\" & Lane'Image);",
            f"               if Extract (R_B, Lane) /= 0.0 then Check (Bits_{vector} (Extract (Divide (R_A, R_B), Lane)) = Bits_{vector} (Extract (R_A, Lane) / Extract (R_B, Lane)), \"{vector} randomized independent division\" & Lane'Image); end if;",
            f"               Check (Test (Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) = Extract (R_B, Lane)) and then Test (Less_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) < Extract (R_B, Lane)) and then Test (Less_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) <= Extract (R_B, Lane)) and then Test (Greater_Than (R_A, R_B), Lane) = (Extract (R_A, Lane) > Extract (R_B, Lane)) and then Test (Greater_Equal (R_A, R_B), Lane) = (Extract (R_A, Lane) >= Extract (R_B, Lane)), \"{vector} randomized independent comparison\" & Lane'Image);",
            f"               Check (Extract (Min_Number (R_A, R_B), Lane) = (if Extract (R_A, Lane) <= Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)) and then Extract (Backends.Native.Min_Number (R_A, R_B), Lane) = (if Extract (R_A, Lane) <= Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)) and then Extract (Max_Number (R_A, R_B), Lane) = (if Extract (R_A, Lane) >= Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)) and then Extract (Backends.Native.Max_Number (R_A, R_B), Lane) = (if Extract (R_A, Lane) >= Extract (R_B, Lane) then Extract (R_A, Lane) else Extract (R_B, Lane)), \"{vector} randomized independent scalar and native min/max\" & Lane'Image);",
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
        "      SNaN32_B : constant F32 := To_F32 (16#FF80_0021#);",
        "      Inf32 : constant F32 := To_F32 (16#7F80_0000#);",
        "      Neg_Zero32 : constant F32 := To_F32 (16#8000_0000#);",
        "      Subnormal32 : constant F32 := To_F32 (16#0000_0001#);",
        "      A32 : constant F32x4 := From_Lanes ([NaN32, Inf32, Neg_Zero32, 0.0]);",
        "      B32 : constant F32x4 := From_Lanes ([1.0, Inf32, 0.0, Neg_Zero32]);",
        "      Slide32 : constant F32x4 := From_Lanes ([NaN32, SNaN32, Inf32, Neg_Zero32]);",
        "      Two32_Right : constant F32x4 := From_Lanes ([Neg_Zero32, Inf32, SNaN32, NaN32]);",
        "      Permute32_Selectors : constant Lane_Selectors_32x4 := [3, 0, 1, 1];",
        "      Permute32_Map : constant Lane_Map_32x4 := Make_Lane_Map (Permute32_Selectors);",
        "      Two32_Map_A : constant Two_Source_Lane_Map_32x4 := Make_Two_Source_Lane_Map ([Select_Left_Lane (0), Select_Right_Lane (1), Select_Left_Lane (2), Select_Right_Lane (3)]);",
        "      Two32_Map_B : constant Two_Source_Lane_Map_32x4 := Make_Two_Source_Lane_Map ([Select_Right_Lane (0), Select_Left_Lane (1), Select_Right_Lane (2), Select_Left_Lane (3)]);",
        "      NaN64 : constant F64 := To_F64 (16#7FF8_0000_0000_0001#);",
        "      SNaN64 : constant F64 := To_F64 (16#7FF0_0000_0000_0001#);",
        "      SNaN64_B : constant F64 := To_F64 (16#FFF0_0000_0000_0021#);",
        "      Inf64 : constant F64 := To_F64 (16#7FF0_0000_0000_0000#);",
        "      Neg_Zero64 : constant F64 := To_F64 (16#8000_0000_0000_0000#);",
        "      Subnormal64 : constant F64 := To_F64 (16#0000_0000_0000_0001#);",
        "      A64 : constant F64x2 := From_Lanes ([NaN64, Neg_Zero64]);",
        "      B64 : constant F64x2 := From_Lanes ([1.0, 0.0]);",
        "      Slide64_A : constant F64x2 := From_Lanes ([NaN64, SNaN64]);",
        "      Slide64_B : constant F64x2 := From_Lanes ([Inf64, Neg_Zero64]);",
        "      Permute64_Selectors : constant Lane_Selectors_64x2 := [1, 0];",
        "      Permute64_Map : constant Lane_Map_64x2 := Make_Lane_Map (Permute64_Selectors);",
        "      Two64_Map_A : constant Two_Source_Lane_Map_64x2 := Make_Two_Source_Lane_Map ([Select_Left_Lane (0), Select_Right_Lane (1)]);",
        "      Two64_Map_B : constant Two_Source_Lane_Map_64x2 := Make_Two_Source_Lane_Map ([Select_Right_Lane (0), Select_Left_Lane (1)]);",
        "      Zero32 : constant F32x4 := From_Lanes ([0.0, 0.0, 0.0, 0.0]);",
        "      Numerator32 : constant F32x4 := From_Lanes ([1.0, 0.0, -1.0, 0.0]);",
        "      Quiet32 : constant F32x4 := From_Lanes ([NaN32, NaN32, NaN32, NaN32]);",
        "      Signal32 : constant F32x4 := From_Lanes ([SNaN32, SNaN32, SNaN32, SNaN32]);",
        "      Number32 : constant F32x4 := From_Lanes ([1.0, 1.0, 1.0, 1.0]);",
        "      Fold_Order32 : constant F32x4 := From_Lanes ([2.0, 1.0, SNaN32, 3.0]);",
        "      Add_Order32 : constant F32x4 := From_Lanes ([1.0E20, 1.0, -1.0E20, 1.0]);",
        "      Add_Negative_Zero32 : constant F32x4 := From_Lanes ([Neg_Zero32, Neg_Zero32, Neg_Zero32, Neg_Zero32]);",
        "      Positive_Zero_First32 : constant F32x4 := From_Lanes ([0.0, Neg_Zero32, 0.0, Neg_Zero32]);",
        "      Negative_Zero_First32 : constant F32x4 := From_Lanes ([Neg_Zero32, 0.0, Neg_Zero32, 0.0]);",
        "      Quiet_Left32 : constant F32x4 := From_Lanes ([NaN32, 5.0, NaN32, NaN32]);",
        "      Quiet_Right32 : constant F32x4 := From_Lanes ([5.0, NaN32, NaN32, NaN32]);",
        "      Signal_Left32 : constant F32x4 := From_Lanes ([SNaN32, 5.0, NaN32, NaN32]);",
        "      Signal_Right32 : constant F32x4 := From_Lanes ([5.0, SNaN32, NaN32, NaN32]);",
        "      Zero64 : constant F64x2 := From_Lanes ([0.0, 0.0]);",
        "      Numerator64 : constant F64x2 := From_Lanes ([1.0, 0.0]);",
        "      Infinity64 : constant F64x2 := From_Lanes ([Inf64, 0.0]);",
        "      Twice64 : constant F64x2 := From_Lanes ([2.0, 0.0]);",
        "      Quiet64 : constant F64x2 := From_Lanes ([NaN64, NaN64]);",
        "      Signal64 : constant F64x2 := From_Lanes ([SNaN64, SNaN64]);",
        "      Number64 : constant F64x2 := From_Lanes ([1.0, 1.0]);",
        "      Positive_Zero_First64 : constant F64x2 := From_Lanes ([0.0, Neg_Zero64]);",
        "      Negative_Zero_First64 : constant F64x2 := From_Lanes ([Neg_Zero64, 0.0]);",
        "      Quiet_Left64 : constant F64x2 := From_Lanes ([NaN64, 5.0]);",
        "      Quiet_Right64 : constant F64x2 := From_Lanes ([5.0, NaN64]);",
        "      Signal_Left64 : constant F64x2 := From_Lanes ([SNaN64, 5.0]);",
        "      Signal_Right64 : constant F64x2 := From_Lanes ([5.0, SNaN64]);",
        "      Add_Negative_Zero64 : constant F64x2 := From_Lanes ([Neg_Zero64, Neg_Zero64]);",
        "      Unordered32_Left : constant F32x4 := From_Lanes ([NaN32, 1.0, SNaN32_B, Inf32]);",
        "      Unordered32_Right : constant F32x4 := From_Lanes ([2.0, SNaN32, NaN32, Neg_Zero32]);",
        "      Unordered64_Left : constant F64x2 := From_Lanes ([NaN64, 1.0]);",
        "      Unordered64_Right : constant F64x2 := From_Lanes ([1.0, SNaN64_B]);",
        "      Unordered64_Both : constant F64x2 := From_Lanes ([SNaN64, Inf64]);",
        "      Unordered64_Both_Right : constant F64x2 := From_Lanes ([NaN64, Neg_Zero64]);",
        "   begin",
        "      for Lane in Lane_Index_32x4 loop",
        "         Check (F32_Bits (Extract (F32x4'(Backends.Native.Zero), Lane)) = 0, \"F32 native positive-zero construction\" & Lane'Image);",
        "         Check (F32_Bits (Extract (Backends.Native.Splat (Neg_Zero32), Lane)) = F32_Bits (Neg_Zero32) and then F32_Bits (Extract (Backends.Native.Splat (NaN32), Lane)) = F32_Bits (NaN32) and then F32_Bits (Extract (Backends.Native.Splat (SNaN32_B), Lane)) = F32_Bits (SNaN32_B) and then F32_Bits (Extract (Backends.Native.Splat (Inf32), Lane)) = F32_Bits (Inf32) and then F32_Bits (Extract (Backends.Native.Splat (Subnormal32), Lane)) = F32_Bits (Subnormal32), \"F32 native special-bit splat\" & Lane'Image);",
        "      end loop;",
        "      for Lane in Lane_Index_64x2 loop",
        "         Check (F64_Bits (Extract (F64x2'(Backends.Native.Zero), Lane)) = 0, \"F64 native positive-zero construction\" & Lane'Image);",
        "         Check (F64_Bits (Extract (Backends.Native.Splat (Neg_Zero64), Lane)) = F64_Bits (Neg_Zero64) and then F64_Bits (Extract (Backends.Native.Splat (NaN64), Lane)) = F64_Bits (NaN64) and then F64_Bits (Extract (Backends.Native.Splat (SNaN64_B), Lane)) = F64_Bits (SNaN64_B) and then F64_Bits (Extract (Backends.Native.Splat (Inf64), Lane)) = F64_Bits (Inf64) and then F64_Bits (Extract (Backends.Native.Splat (Subnormal64), Lane)) = F64_Bits (Subnormal64), \"F64 native special-bit splat\" & Lane'Image);",
        "      end loop;",
        "      for Lane in Lane_Index_32x4 loop",
        "         Check (F32_Bits (Extract (Permute_Lanes (Slide32, Permute32_Map), Lane)) = F32_Bits (Extract (Slide32, Permute32_Selectors (Lane))) and then F32_Bits (Extract (Backends.Native.Permute_Lanes (Slide32, Permute32_Map), Lane)) = F32_Bits (Extract (Slide32, Permute32_Selectors (Lane))), \"F32 special lane permutation\" & Lane'Image);",
        "         Check (F32_Bits (Extract (Permute_Lanes (Slide32, Two32_Right, Two32_Map_A), Lane)) = F32_Bits (Extract ((if Lane mod 2 = 0 then Slide32 else Two32_Right), Lane)) and then F32_Bits (Extract (Backends.Native.Permute_Lanes (Slide32, Two32_Right, Two32_Map_A), Lane)) = F32_Bits (Extract ((if Lane mod 2 = 0 then Slide32 else Two32_Right), Lane)), \"F32 special two-source permutation A\" & Lane'Image);",
        "         Check (F32_Bits (Extract (Permute_Lanes (Slide32, Two32_Right, Two32_Map_B), Lane)) = F32_Bits (Extract ((if Lane mod 2 = 0 then Two32_Right else Slide32), Lane)) and then F32_Bits (Extract (Backends.Native.Permute_Lanes (Slide32, Two32_Right, Two32_Map_B), Lane)) = F32_Bits (Extract ((if Lane mod 2 = 0 then Two32_Right else Slide32), Lane)), \"F32 special two-source permutation B\" & Lane'Image);",
        "      end loop;",
        "      for Pattern in Natural range 0 .. 15 loop",
        "         for Lane in Lane_Index_32x4 loop",
        "            Check (F32_Bits (Extract (Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), Slide32, Two32_Right), Lane)) = F32_Bits ((if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (Slide32, Lane) else Extract (Two32_Right, Lane))) and then F32_Bits (Backends.Native.Extract (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), Slide32, Two32_Right), Lane)) = F32_Bits ((if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (Slide32, Lane) else Extract (Two32_Right, Lane))), \"F32 special bitwise scalar and native select\" & Pattern'Image & Lane'Image);",
        "         end loop;",
        "      end loop;",
        "      for Pattern in Natural range 0 .. 15 loop",
        "         declare",
        "            Mask : constant Mask_32x4 := Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern));",
        "            Packed : constant F32x4 := Reference_Compress_F32x4 (Slide32, Mask);",
        "            Spread : constant F32x4 := Reference_Expand_F32x4 (Slide32, Mask);",
        "         begin",
        "            Check (Same (Compress (Slide32, Mask), Packed) and then Same (Backends.Native.Compress (Slide32, Mask), Packed), \"F32 special compress\" & Pattern'Image);",
        "            Check (Same (Expand (Slide32, Mask), Spread) and then Same (Backends.Native.Expand (Slide32, Mask), Spread), \"F32 special expand\" & Pattern'Image);",
        "         end;",
        "      end loop;",
        "      for Lane in Lane_Index_64x2 loop",
        "         Check (F64_Bits (Extract (Permute_Lanes (Slide64_A, Permute64_Map), Lane)) = F64_Bits (Extract (Slide64_A, Permute64_Selectors (Lane))) and then F64_Bits (Extract (Backends.Native.Permute_Lanes (Slide64_A, Permute64_Map), Lane)) = F64_Bits (Extract (Slide64_A, Permute64_Selectors (Lane))) and then F64_Bits (Extract (Backends.Native.Permute_Lanes (Slide64_B, Permute64_Map), Lane)) = F64_Bits (Extract (Slide64_B, Permute64_Selectors (Lane))), \"F64 special lane permutation\" & Lane'Image);",
        "         Check (F64_Bits (Extract (Permute_Lanes (Slide64_A, Slide64_B, Two64_Map_A), Lane)) = F64_Bits (Extract ((if Lane = 0 then Slide64_A else Slide64_B), Lane)) and then F64_Bits (Extract (Backends.Native.Permute_Lanes (Slide64_A, Slide64_B, Two64_Map_A), Lane)) = F64_Bits (Extract ((if Lane = 0 then Slide64_A else Slide64_B), Lane)), \"F64 special two-source permutation A\" & Lane'Image);",
        "         Check (F64_Bits (Extract (Permute_Lanes (Slide64_A, Slide64_B, Two64_Map_B), Lane)) = F64_Bits (Extract ((if Lane = 0 then Slide64_B else Slide64_A), Lane)) and then F64_Bits (Extract (Backends.Native.Permute_Lanes (Slide64_A, Slide64_B, Two64_Map_B), Lane)) = F64_Bits (Extract ((if Lane = 0 then Slide64_B else Slide64_A), Lane)), \"F64 special two-source permutation B\" & Lane'Image);",
        "      end loop;",
        "      for Pattern in Natural range 0 .. 3 loop",
        "         for Lane in Lane_Index_64x2 loop",
        "            Check (F64_Bits (Extract (Select_Value (Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), Slide64_A, Slide64_B), Lane)) = F64_Bits ((if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (Slide64_A, Lane) else Extract (Slide64_B, Lane))) and then F64_Bits (Backends.Native.Extract (Backends.Native.Select_Value (Backends.Native.Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern)), Slide64_A, Slide64_B), Lane)) = F64_Bits ((if (Pattern / 2 ** Lane) mod 2 = 1 then Extract (Slide64_A, Lane) else Extract (Slide64_B, Lane))), \"F64 special bitwise scalar and native select\" & Pattern'Image & Lane'Image);",
        "         end loop;",
        "      end loop;",
        "      for Pattern in Natural range 0 .. 3 loop",
        "         declare",
        "            Mask : constant Mask_64x2 := Mask_From_Bit_Mask (Interfaces.Unsigned_8 (Pattern));",
        "            Packed_A : constant F64x2 := Reference_Compress_F64x2 (Slide64_A, Mask);",
        "            Spread_A : constant F64x2 := Reference_Expand_F64x2 (Slide64_A, Mask);",
        "            Packed_B : constant F64x2 := Reference_Compress_F64x2 (Slide64_B, Mask);",
        "            Spread_B : constant F64x2 := Reference_Expand_F64x2 (Slide64_B, Mask);",
        "         begin",
        "            Check (Same (Compress (Slide64_A, Mask), Packed_A) and then Same (Backends.Native.Compress (Slide64_A, Mask), Packed_A) and then Same (Compress (Slide64_B, Mask), Packed_B) and then Same (Backends.Native.Compress (Slide64_B, Mask), Packed_B), \"F64 special compress\" & Pattern'Image);",
        "            Check (Same (Expand (Slide64_A, Mask), Spread_A) and then Same (Backends.Native.Expand (Slide64_A, Mask), Spread_A) and then Same (Expand (Slide64_B, Mask), Spread_B) and then Same (Backends.Native.Expand (Slide64_B, Mask), Spread_B), \"F64 special expand\" & Pattern'Image);",
        "         end;",
        "      end loop;",
        "      for Slide in Natural range 0 .. 6 loop",
        "         for Lane in Lane_Index_32x4 loop",
        "            declare",
        "               Expected_Low : constant Interfaces.Unsigned_32 := (if Slide < 4 and then Lane < 4 - Slide then F32_Bits (Extract (Slide32, Lane_Index_32x4 (Lane + Slide))) else 0);",
        "               Expected_High : constant Interfaces.Unsigned_32 := (if Slide < 4 and then Lane >= Slide then F32_Bits (Extract (Slide32, Lane_Index_32x4 (Lane - Slide))) else 0);",
        "            begin",
        "               Check (F32_Bits (Extract (Slide_Lanes_Toward_Low (Slide32, Slide), Lane)) = Expected_Low and then F32_Bits (Extract (Backends.Native.Slide_Lanes_Toward_Low (Slide32, Slide), Lane)) = Expected_Low, \"F32 special slide toward low\" & Slide'Image & Lane'Image);",
        "               Check (F32_Bits (Extract (Slide_Lanes_Toward_High (Slide32, Slide), Lane)) = Expected_High and then F32_Bits (Extract (Backends.Native.Slide_Lanes_Toward_High (Slide32, Slide), Lane)) = Expected_High, \"F32 special slide toward high\" & Slide'Image & Lane'Image);",
        "            end;",
        "         end loop;",
        "      end loop;",
        "      for Slide in Natural range 0 .. 4 loop",
        "         for Lane in Lane_Index_64x2 loop",
        "            for Source_Choice in Boolean loop",
        "               declare",
        "                  Source : constant F64x2 := (if Source_Choice then Slide64_A else Slide64_B);",
        "                  Expected_Low : constant Interfaces.Unsigned_64 := (if Slide < 2 and then Lane < 2 - Slide then F64_Bits (Extract (Source, Lane_Index_64x2 (Lane + Slide))) else 0);",
        "                  Expected_High : constant Interfaces.Unsigned_64 := (if Slide < 2 and then Lane >= Slide then F64_Bits (Extract (Source, Lane_Index_64x2 (Lane - Slide))) else 0);",
        "               begin",
        "                  Check (F64_Bits (Extract (Slide_Lanes_Toward_Low (Source, Slide), Lane)) = Expected_Low and then F64_Bits (Extract (Backends.Native.Slide_Lanes_Toward_Low (Source, Slide), Lane)) = Expected_Low, \"F64 special slide toward low\" & Slide'Image & Lane'Image);",
        "                  Check (F64_Bits (Extract (Slide_Lanes_Toward_High (Source, Slide), Lane)) = Expected_High and then F64_Bits (Extract (Backends.Native.Slide_Lanes_Toward_High (Source, Slide), Lane)) = Expected_High, \"F64 special slide toward high\" & Slide'Image & Lane'Image);",
        "               end;",
        "            end loop;",
        "         end loop;",
        "      end loop;",
        "      Check (Flyology_SIMD.To_Bit_Mask (Unordered (Unordered32_Left, Unordered32_Right)) = 7 and then Backends.Native.To_Bit_Mask (Backends.Native.Unordered (Unordered32_Left, Unordered32_Right)) = 7, \"F32 independent fixed unordered oracle\");",
        "      Check (Extract (Backends.Native.Min_Number (A32, B32), 0) = 1.0 and then Extract (Backends.Native.Max_Number (A32, B32), 0) = 1.0, \"F32 quiet NaN returns number\");",
        "      Check ((F32_Bits (Extract (Backends.Native.Min_Number (From_Lanes ([SNaN32, 0.0, 0.0, 0.0]), B32), 0)) and 16#7FC0_0000#) = 16#7FC0_0000#, \"F32 signaling NaN is quieted\");",
        "      Check (F32_Bits (Extract (Min_Number (A32, B32), 2)) = 16#8000_0000# and then F32_Bits (Extract (Max_Number (A32, B32), 2)) = 0 and then F32_Bits (Extract (Min_Number (B32, A32), 2)) = 16#8000_0000# and then F32_Bits (Extract (Max_Number (B32, A32), 2)) = 0 and then F32_Bits (Extract (Backends.Native.Min_Number (A32, B32), 2)) = 16#8000_0000# and then F32_Bits (Extract (Backends.Native.Max_Number (A32, B32), 2)) = 0 and then F32_Bits (Extract (Backends.Native.Min_Number (B32, A32), 2)) = 16#8000_0000# and then F32_Bits (Extract (Backends.Native.Max_Number (B32, A32), 2)) = 0, \"F32 signed zero operand orders\");",
        "      Check (Extract (Min_Number (Quiet32, Number32), 0) = 1.0 and then Extract (Max_Number (Quiet32, Number32), 0) = 1.0 and then Extract (Min_Number (Number32, Quiet32), 0) = 1.0 and then Extract (Max_Number (Number32, Quiet32), 0) = 1.0 and then Extract (Backends.Native.Min_Number (Quiet32, Number32), 0) = 1.0 and then Extract (Backends.Native.Max_Number (Quiet32, Number32), 0) = 1.0 and then Extract (Backends.Native.Min_Number (Number32, Quiet32), 0) = 1.0 and then Extract (Backends.Native.Max_Number (Number32, Quiet32), 0) = 1.0, \"F32 quiet NaN operand orders\");",
        "      Check (Is_Quiet_NaN (Extract (Min_Number (Signal32, Number32), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Signal32, Number32), 0)) and then Is_Quiet_NaN (Extract (Min_Number (Number32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Number32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Signal32, Number32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Signal32, Number32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Number32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Number32, Signal32), 0)), \"F32 signaling NaN operand orders\");",
        "      Check (Is_Quiet_NaN (Extract (Min_Number (Quiet32, Quiet32), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Quiet32, Quiet32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Quiet32, Quiet32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Quiet32, Quiet32), 0)), \"F32 two quiet NaNs\");",
        "      Check (Is_Quiet_NaN (Extract (Min_Number (Signal32, Quiet32), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Signal32, Quiet32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Signal32, Quiet32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Signal32, Quiet32), 0)), \"F32 signaling then quiet NaN\");",
        "      Check (Is_Quiet_NaN (Extract (Min_Number (Quiet32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Quiet32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Quiet32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Quiet32, Signal32), 0)), \"F32 quiet then signaling NaN\");",
        "      Check (Is_Quiet_NaN (Extract (Min_Number (Signal32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Signal32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Signal32, Signal32), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Signal32, Signal32), 0)), \"F32 two signaling NaNs\");",
        "      Check (F32_Bits (Extract (Backends.Native.Min_Number (From_Lanes ([SNaN32, 0.0, 0.0, 0.0]), From_Lanes ([SNaN32_B, 0.0, 0.0, 0.0])), 0)) = (F32_Bits (SNaN32) or 16#0040_0000#) and then F32_Bits (Extract (Backends.Native.Max_Number (From_Lanes ([SNaN32_B, 0.0, 0.0, 0.0]), From_Lanes ([SNaN32, 0.0, 0.0, 0.0])), 0)) = (F32_Bits (SNaN32_B) or 16#0040_0000#), \"F32 signaling NaN left precedence\");",
        "      Check (Is_NaN (Extract (Add (A32, B32), 0)) and then Is_NaN (Extract (Backends.Native.Add (A32, B32), 0)), \"F32 NaN addition\");",
        "      Check (Is_NaN (Extract (Subtract (A32, B32), 1)) and then Is_NaN (Extract (Backends.Native.Subtract (A32, B32), 1)), \"F32 infinity subtraction\");",
        "      Check (F32_Bits (Extract (Multiply (A32, B32), 1)) = 16#7F80_0000# and then F32_Bits (Extract (Backends.Native.Multiply (A32, B32), 1)) = 16#7F80_0000#, \"F32 infinity multiplication\");",
        "      Check (F32_Bits (Extract (Divide (Numerator32, Zero32), 0)) = 16#7F80_0000# and then F32_Bits (Extract (Backends.Native.Divide (Numerator32, Zero32), 0)) = 16#7F80_0000# and then Is_NaN (Extract (Divide (Numerator32, Zero32), 1)) and then Is_NaN (Extract (Backends.Native.Divide (Numerator32, Zero32), 1)), \"F32 division edge cases\");",
        "      Check (Is_NaN (Reduce_Add (A32)) and then Is_NaN (Backends.Native.Reduce_Add (A32)), \"F32 NaN reduction\");",
        "      Check (Is_Quiet_NaN (Reduce_Add (Signal32)) and then Is_Quiet_NaN (Backends.Native.Reduce_Add (Signal32)), \"F32 signaling NaN addition reduction\");",
        "      Check (F32_Bits (Reduce_Add (Add_Negative_Zero32)) = 0 and then F32_Bits (Backends.Native.Reduce_Add (Add_Negative_Zero32)) = 0, \"F32 positive-zero reduction start\");",
        "      Check (Reduce_Add (Add_Order32) = 1.0 and then Backends.Native.Reduce_Add (Add_Order32) = 1.0, \"F32 ascending addition order\");",
        "      Check (F32_Bits (Reduce_Min_Number (A32)) = 16#8000_0000# and then F32_Bits (Backends.Native.Reduce_Min_Number (A32)) = 16#8000_0000# and then F32_Bits (Reduce_Max_Number (A32)) = 16#7F80_0000# and then F32_Bits (Backends.Native.Reduce_Max_Number (A32)) = 16#7F80_0000#, \"F32 min/max reduction NaN and signed zero\");",
        "      Check (Is_Quiet_NaN (Reduce_Min_Number (Signal32)) and then Is_Quiet_NaN (Reduce_Max_Number (Signal32)) and then Is_Quiet_NaN (Backends.Native.Reduce_Min_Number (Signal32)) and then Is_Quiet_NaN (Backends.Native.Reduce_Max_Number (Signal32)), \"F32 signaling NaN reductions\");",
        "      Check (Reduce_Min_Number (Fold_Order32) = 3.0 and then Reduce_Max_Number (Fold_Order32) = 3.0 and then Backends.Native.Reduce_Min_Number (Fold_Order32) = 3.0 and then Backends.Native.Reduce_Max_Number (Fold_Order32) = 3.0, \"F32 ascending fold order\");",
        "      Check (F32_Bits (Reduce_Min_Number (Positive_Zero_First32)) = 16#8000_0000# and then F32_Bits (Reduce_Max_Number (Positive_Zero_First32)) = 0 and then F32_Bits (Reduce_Min_Number (Negative_Zero_First32)) = 16#8000_0000# and then F32_Bits (Reduce_Max_Number (Negative_Zero_First32)) = 0 and then F32_Bits (Backends.Native.Reduce_Min_Number (Positive_Zero_First32)) = 16#8000_0000# and then F32_Bits (Backends.Native.Reduce_Max_Number (Positive_Zero_First32)) = 0 and then F32_Bits (Backends.Native.Reduce_Min_Number (Negative_Zero_First32)) = 16#8000_0000# and then F32_Bits (Backends.Native.Reduce_Max_Number (Negative_Zero_First32)) = 0, \"F32 reduction signed-zero orders\");",
        "      Check (Reduce_Min_Number (Quiet_Left32) = 5.0 and then Reduce_Max_Number (Quiet_Left32) = 5.0 and then Reduce_Min_Number (Quiet_Right32) = 5.0 and then Reduce_Max_Number (Quiet_Right32) = 5.0 and then Backends.Native.Reduce_Min_Number (Quiet_Left32) = 5.0 and then Backends.Native.Reduce_Max_Number (Quiet_Left32) = 5.0 and then Backends.Native.Reduce_Min_Number (Quiet_Right32) = 5.0 and then Backends.Native.Reduce_Max_Number (Quiet_Right32) = 5.0, \"F32 reduction quiet-NaN orders\");",
        "      Check (Is_Quiet_NaN (Reduce_Min_Number (Signal_Left32)) and then Is_Quiet_NaN (Reduce_Max_Number (Signal_Left32)) and then Is_Quiet_NaN (Reduce_Min_Number (Signal_Right32)) and then Is_Quiet_NaN (Reduce_Max_Number (Signal_Right32)) and then Is_Quiet_NaN (Backends.Native.Reduce_Min_Number (Signal_Left32)) and then Is_Quiet_NaN (Backends.Native.Reduce_Max_Number (Signal_Left32)) and then Is_Quiet_NaN (Backends.Native.Reduce_Min_Number (Signal_Right32)) and then Is_Quiet_NaN (Backends.Native.Reduce_Max_Number (Signal_Right32)), \"F32 reduction signaling-NaN orders\");",
        "      Check (Flyology_SIMD.To_Bit_Mask (Unordered (Unordered64_Left, Unordered64_Right)) = 3 and then Backends.Native.To_Bit_Mask (Backends.Native.Unordered (Unordered64_Left, Unordered64_Right)) = 3 and then Flyology_SIMD.To_Bit_Mask (Unordered (Unordered64_Both, Unordered64_Both_Right)) = 1 and then Backends.Native.To_Bit_Mask (Backends.Native.Unordered (Unordered64_Both, Unordered64_Both_Right)) = 1, \"F64 independent fixed unordered oracle\");",
        "      for Iteration in 1 .. 250 loop",
        "         declare",
        "            Left32_Lanes : Lane_Values_F32x4;",
        "            Right32_Lanes : Lane_Values_F32x4;",
        "            Left64_Lanes : Lane_Values_F64x2;",
        "            Right64_Lanes : Lane_Values_F64x2;",
        "            Expected32 : Interfaces.Unsigned_8 := 0;",
        "            Expected64 : Interfaces.Unsigned_8 := 0;",
        "         begin",
        "            for Lane in Lane_Index_32x4 loop",
        "               Left32_Lanes (Lane) := To_F32 (Interfaces.Unsigned_32 (Next_U64 and 16#FFFF_FFFF#));",
        "               Right32_Lanes (Lane) := To_F32 (Interfaces.Unsigned_32 (Next_U64 and 16#FFFF_FFFF#));",
        "               if Is_NaN (Left32_Lanes (Lane)) or else Is_NaN (Right32_Lanes (Lane)) then Expected32 := Expected32 or Interfaces.Shift_Left (Interfaces.Unsigned_8 (1), Lane); end if;",
        "            end loop;",
        "            for Lane in Lane_Index_64x2 loop",
        "               Left64_Lanes (Lane) := To_F64 (Next_U64);",
        "               Right64_Lanes (Lane) := To_F64 (Next_U64);",
        "               if Is_NaN (Left64_Lanes (Lane)) or else Is_NaN (Right64_Lanes (Lane)) then Expected64 := Expected64 or Interfaces.Shift_Left (Interfaces.Unsigned_8 (1), Lane); end if;",
        "            end loop;",
        "            declare",
        "               Left32 : constant F32x4 := From_Lanes (Left32_Lanes);",
        "               Right32 : constant F32x4 := From_Lanes (Right32_Lanes);",
        "               Left64 : constant F64x2 := From_Lanes (Left64_Lanes);",
        "               Right64 : constant F64x2 := From_Lanes (Right64_Lanes);",
        "            begin",
        "               Check (Flyology_SIMD.To_Bit_Mask (Unordered (Left32, Right32)) = Expected32 and then Backends.Native.To_Bit_Mask (Backends.Native.Unordered (Left32, Right32)) = Expected32, \"F32 randomized raw-bit unordered oracle\" & Iteration'Image);",
        "               Check (Flyology_SIMD.To_Bit_Mask (Unordered (Left64, Right64)) = Expected64 and then Backends.Native.To_Bit_Mask (Backends.Native.Unordered (Left64, Right64)) = Expected64, \"F64 randomized raw-bit unordered oracle\" & Iteration'Image);",
        "            end;",
        "         end;",
        "      end loop;",
        "      Check (Extract (Backends.Native.Min_Number (A64, B64), 0) = 1.0 and then Extract (Backends.Native.Max_Number (A64, B64), 0) = 1.0, \"F64 quiet NaN returns number\");",
        "      Check ((F64_Bits (Extract (Backends.Native.Max_Number (From_Lanes ([SNaN64, 0.0]), B64), 0)) and 16#7FF8_0000_0000_0000#) = 16#7FF8_0000_0000_0000#, \"F64 signaling NaN is quieted\");",
        "      Check (F64_Bits (Extract (Min_Number (A64, B64), 1)) = 16#8000_0000_0000_0000# and then F64_Bits (Extract (Max_Number (A64, B64), 1)) = 0 and then F64_Bits (Extract (Min_Number (B64, A64), 1)) = 16#8000_0000_0000_0000# and then F64_Bits (Extract (Max_Number (B64, A64), 1)) = 0 and then F64_Bits (Extract (Backends.Native.Min_Number (A64, B64), 1)) = 16#8000_0000_0000_0000# and then F64_Bits (Extract (Backends.Native.Max_Number (A64, B64), 1)) = 0 and then F64_Bits (Extract (Backends.Native.Min_Number (B64, A64), 1)) = 16#8000_0000_0000_0000# and then F64_Bits (Extract (Backends.Native.Max_Number (B64, A64), 1)) = 0, \"F64 signed zero operand orders\");",
        "      Check (Extract (Min_Number (Quiet64, Number64), 0) = 1.0 and then Extract (Max_Number (Quiet64, Number64), 0) = 1.0 and then Extract (Min_Number (Number64, Quiet64), 0) = 1.0 and then Extract (Max_Number (Number64, Quiet64), 0) = 1.0 and then Extract (Backends.Native.Min_Number (Quiet64, Number64), 0) = 1.0 and then Extract (Backends.Native.Max_Number (Quiet64, Number64), 0) = 1.0 and then Extract (Backends.Native.Min_Number (Number64, Quiet64), 0) = 1.0 and then Extract (Backends.Native.Max_Number (Number64, Quiet64), 0) = 1.0, \"F64 quiet NaN operand orders\");",
        "      Check (Is_Quiet_NaN (Extract (Min_Number (Signal64, Number64), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Signal64, Number64), 0)) and then Is_Quiet_NaN (Extract (Min_Number (Number64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Number64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Signal64, Number64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Signal64, Number64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Number64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Number64, Signal64), 0)), \"F64 signaling NaN operand orders\");",
        "      Check (Is_Quiet_NaN (Extract (Min_Number (Quiet64, Quiet64), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Quiet64, Quiet64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Quiet64, Quiet64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Quiet64, Quiet64), 0)), \"F64 two quiet NaNs\");",
        "      Check (Is_Quiet_NaN (Extract (Min_Number (Signal64, Quiet64), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Signal64, Quiet64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Signal64, Quiet64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Signal64, Quiet64), 0)), \"F64 signaling then quiet NaN\");",
        "      Check (Is_Quiet_NaN (Extract (Min_Number (Quiet64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Quiet64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Quiet64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Quiet64, Signal64), 0)), \"F64 quiet then signaling NaN\");",
        "      Check (Is_Quiet_NaN (Extract (Min_Number (Signal64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Max_Number (Signal64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Min_Number (Signal64, Signal64), 0)) and then Is_Quiet_NaN (Extract (Backends.Native.Max_Number (Signal64, Signal64), 0)), \"F64 two signaling NaNs\");",
        "      Check (F64_Bits (Extract (Backends.Native.Min_Number (From_Lanes ([SNaN64, 0.0]), From_Lanes ([SNaN64_B, 0.0])), 0)) = (F64_Bits (SNaN64) or 16#0008_0000_0000_0000#) and then F64_Bits (Extract (Backends.Native.Max_Number (From_Lanes ([SNaN64_B, 0.0]), From_Lanes ([SNaN64, 0.0])), 0)) = (F64_Bits (SNaN64_B) or 16#0008_0000_0000_0000#), \"F64 signaling NaN left precedence\");",
        "      Check (Is_NaN (Extract (Add (A64, B64), 0)) and then Is_NaN (Extract (Backends.Native.Add (A64, B64), 0)), \"F64 NaN addition\");",
        "      Check (Is_NaN (Extract (Subtract (Infinity64, Infinity64), 0)) and then Is_NaN (Extract (Backends.Native.Subtract (Infinity64, Infinity64), 0)), \"F64 infinity subtraction\");",
        "      Check (F64_Bits (Extract (Multiply (Infinity64, Twice64), 0)) = 16#7FF0_0000_0000_0000# and then F64_Bits (Extract (Backends.Native.Multiply (Infinity64, Twice64), 0)) = 16#7FF0_0000_0000_0000#, \"F64 infinity multiplication\");",
        "      Check (F64_Bits (Extract (Divide (Numerator64, Zero64), 0)) = 16#7FF0_0000_0000_0000# and then F64_Bits (Extract (Backends.Native.Divide (Numerator64, Zero64), 0)) = 16#7FF0_0000_0000_0000# and then Is_NaN (Extract (Divide (Numerator64, Zero64), 1)) and then Is_NaN (Extract (Backends.Native.Divide (Numerator64, Zero64), 1)), \"F64 division edge cases\");",
        "      Check (Is_NaN (Reduce_Add (A64)) and then Is_NaN (Backends.Native.Reduce_Add (A64)), \"F64 NaN reduction\");",
        "      Check (Is_Quiet_NaN (Reduce_Add (Signal64)) and then Is_Quiet_NaN (Backends.Native.Reduce_Add (Signal64)), \"F64 signaling NaN addition reduction\");",
        "      Check (F64_Bits (Reduce_Add (Add_Negative_Zero64)) = 0 and then F64_Bits (Backends.Native.Reduce_Add (Add_Negative_Zero64)) = 0, \"F64 positive-zero reduction start\");",
        "      Check (F64_Bits (Reduce_Min_Number (A64)) = 16#8000_0000_0000_0000# and then F64_Bits (Backends.Native.Reduce_Min_Number (A64)) = 16#8000_0000_0000_0000# and then F64_Bits (Reduce_Max_Number (A64)) = 16#8000_0000_0000_0000# and then F64_Bits (Backends.Native.Reduce_Max_Number (A64)) = 16#8000_0000_0000_0000#, \"F64 min/max reduction NaN and signed zero\");",
        "      Check (Is_Quiet_NaN (Reduce_Min_Number (Signal64)) and then Is_Quiet_NaN (Reduce_Max_Number (Signal64)) and then Is_Quiet_NaN (Backends.Native.Reduce_Min_Number (Signal64)) and then Is_Quiet_NaN (Backends.Native.Reduce_Max_Number (Signal64)), \"F64 signaling NaN reductions\");",
        "      Check (F64_Bits (Reduce_Min_Number (Positive_Zero_First64)) = 16#8000_0000_0000_0000# and then F64_Bits (Reduce_Max_Number (Positive_Zero_First64)) = 0 and then F64_Bits (Reduce_Min_Number (Negative_Zero_First64)) = 16#8000_0000_0000_0000# and then F64_Bits (Reduce_Max_Number (Negative_Zero_First64)) = 0 and then F64_Bits (Backends.Native.Reduce_Min_Number (Positive_Zero_First64)) = 16#8000_0000_0000_0000# and then F64_Bits (Backends.Native.Reduce_Max_Number (Positive_Zero_First64)) = 0 and then F64_Bits (Backends.Native.Reduce_Min_Number (Negative_Zero_First64)) = 16#8000_0000_0000_0000# and then F64_Bits (Backends.Native.Reduce_Max_Number (Negative_Zero_First64)) = 0, \"F64 reduction signed-zero orders\");",
        "      Check (Reduce_Min_Number (Quiet_Left64) = 5.0 and then Reduce_Max_Number (Quiet_Left64) = 5.0 and then Reduce_Min_Number (Quiet_Right64) = 5.0 and then Reduce_Max_Number (Quiet_Right64) = 5.0 and then Backends.Native.Reduce_Min_Number (Quiet_Left64) = 5.0 and then Backends.Native.Reduce_Max_Number (Quiet_Left64) = 5.0 and then Backends.Native.Reduce_Min_Number (Quiet_Right64) = 5.0 and then Backends.Native.Reduce_Max_Number (Quiet_Right64) = 5.0, \"F64 reduction quiet-NaN orders\");",
        "      Check (Is_Quiet_NaN (Reduce_Min_Number (Signal_Left64)) and then Is_Quiet_NaN (Reduce_Max_Number (Signal_Left64)) and then Is_Quiet_NaN (Reduce_Min_Number (Signal_Right64)) and then Is_Quiet_NaN (Reduce_Max_Number (Signal_Right64)) and then Is_Quiet_NaN (Backends.Native.Reduce_Min_Number (Signal_Left64)) and then Is_Quiet_NaN (Backends.Native.Reduce_Max_Number (Signal_Left64)) and then Is_Quiet_NaN (Backends.Native.Reduce_Min_Number (Signal_Right64)) and then Is_Quiet_NaN (Backends.Native.Reduce_Max_Number (Signal_Right64)), \"F64 reduction signaling-NaN orders\");",
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
    native_spec = document_spec(
        replace_block(text, "GENERATED FULL-FAMILY BACKEND CONTRACT", contract()),
        support="native",
    )
    SPEC.write_text(native_spec)
    SCALAR_SPEC.write_text(scalar_contract(native_spec))
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
