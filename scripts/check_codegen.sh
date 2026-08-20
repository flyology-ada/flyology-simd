#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
architecture=${1:-aarch64}
avx2=${2:-disabled}
wide_backend=${3:-composed}
temporary=$(mktemp -d "${TMPDIR:-/tmp}/flyology-simd-codegen.XXXXXX")
trap 'rm -rf "$temporary"' EXIT HUP INT TERM

cd "$project_root"
alr build -- "-XFLYOLOGY_SIMD_ARCH=$architecture" \
  "-XFLYOLOGY_SIMD_AVX2=$avx2" \
  "-XFLYOLOGY_SIMD_WIDE_BACKEND=$wide_backend"
alr exec -- gprbuild -f -p -P scripts/codegen_probes.gpr \
  "-XFLYOLOGY_SIMD_ARCH=$architecture" \
  "-XFLYOLOGY_SIMD_AVX2=$avx2" \
  "-XFLYOLOGY_SIMD_WIDE_BACKEND=$wide_backend"

object_root="obj/$architecture/$avx2/$wide_backend"
probe_root="obj/codegen-probes/$architecture/$avx2/$wide_backend"
native_object="$object_root/flyology_simd-backends-native.o"
algorithm_object="$object_root/flyology_simd-algorithms-native.o"
floating_algorithm_object="$object_root/flyology_simd-algorithms-native_floating.o"
feature_object="$object_root/flyology_simd-features.o"
slide_probe_object="$probe_root/slide_codegen_probe.o"
permute_probe_object="$probe_root/permute_codegen_probe.o"
wide_probe_object="$probe_root/wide_codegen_probe.o"
wide_reduction_probe_object="$probe_root/wide_reduction_codegen_probe.o"
wide_construction_probe_object="$probe_root/wide_construction_codegen_probe.o"
wide_comparison_probe_object="$probe_root/wide_comparison_codegen_probe.o"
wide_saturating_arithmetic_probe_object="$probe_root/wide_saturating_arithmetic_codegen_probe.o"
wide_wrapping_arithmetic_probe_object="$probe_root/wide_wrapping_arithmetic_codegen_probe.o"
wide_bitwise_probe_object="$probe_root/wide_bitwise_codegen_probe.o"
wide_shift_probe_object="$probe_root/wide_shift_codegen_probe.o"
wide_minmax_probe_object="$probe_root/wide_minmax_codegen_probe.o"
wide_mask_probe_object="$probe_root/wide_mask_codegen_probe.o"
wide_float_reduction_probe_object="$probe_root/wide_float_reduction_codegen_probe.o"
wide_compact_probe_object="$probe_root/wide_compact_codegen_probe.o"
wide_movement_probe_object="$probe_root/wide_movement_codegen_probe.o"
wide_numeric_conversion_probe_object="$probe_root/wide_numeric_conversion_codegen_probe.o"
wide_memory_probe_object="$probe_root/wide_memory_codegen_probe.o"
float_reduction_probe_object="$probe_root/float_reduction_codegen_probe.o"
conversion64_probe_object="$probe_root/conversion64_codegen_probe.o"
integer_shift_probe_object="$probe_root/integer_shift_codegen_probe.o"
unordered_probe_object="$probe_root/unordered_codegen_probe.o"
mask_position_probe_object="$probe_root/mask_position_codegen_probe.o"
mask_core_probe_object="$probe_root/mask_core_codegen_probe.o"
construction_probe_object="$probe_root/construction_codegen_probe.o"
partial_memory_probe_object="$probe_root/partial_memory_codegen_probe.o"
bit_cast_probe_object="$probe_root/bit_cast_codegen_probe.o"
alignment_probe_object="$probe_root/alignment_codegen_probe.o"
table_lookup_probe_object="$probe_root/table_lookup_codegen_probe.o"
u8_value_probe_object="$probe_root/u8_value_codegen_probe.o"
integer_reduction_probe_object="$probe_root/integer_reduction_codegen_probe.o"
float_binary_probe_object="$probe_root/float_binary_codegen_probe.o"
complete_memory_probe_object="$probe_root/complete_memory_codegen_probe.o"
comparison_probe_object="$probe_root/comparison_codegen_probe.o"
wrapping_arithmetic_probe_object="$probe_root/wrapping_arithmetic_codegen_probe.o"
lane_arrangement_probe_object="$probe_root/lane_arrangement_codegen_probe.o"
bitwise_probe_object="$probe_root/bitwise_codegen_probe.o"
integer_minmax_probe_object="$probe_root/integer_minmax_codegen_probe.o"
saturating_arithmetic_probe_object="$probe_root/saturating_arithmetic_codegen_probe.o"
integer_conversion_probe_object="$probe_root/integer_conversion_codegen_probe.o"
wide_byte_object="$object_root/flyology_simd-wide-byte_avx2_leaf.o"
wide_float_object="$object_root/flyology_simd-wide-float_avx2_leaf.o"
wide_lookup_object="$object_root/flyology_simd-wide-lookup_mechanism.o"
wide_permute_object="$object_root/flyology_simd-wide-permute_mechanism.o"
wide_compact_object="$object_root/flyology_simd-wide-compact_mechanism.o"
wide_float_reduction_leaf_object="$object_root/flyology_simd-wide-float_reduce_selected_leaf.o"

disassemble() {
    if command -v otool >/dev/null 2>&1; then
        otool -tvV "$1"
    else
        objdump -dr "$1"
    fi
}

disassemble "$native_object" >"$temporary/native.txt"
if command -v otool >/dev/null 2>&1; then
    objdump -dr --show-all-symbols "$algorithm_object" |
      grep -Ev '<ltmp[0-9]+>:$' >"$temporary/algorithm.txt"
else
    disassemble "$algorithm_object" >"$temporary/algorithm.txt"
fi
if command -v otool >/dev/null 2>&1; then
    objdump -dr --show-all-symbols "$floating_algorithm_object" |
      grep -Ev '<ltmp[0-9]+>:$' >"$temporary/floating-algorithm.txt"
else
    disassemble "$floating_algorithm_object" \
      >"$temporary/floating-algorithm.txt"
fi
nm -u "$floating_algorithm_object" \
  >"$temporary/floating-algorithm-undefined.txt"
disassemble "$feature_object" >"$temporary/features.txt"
disassemble "$slide_probe_object" >"$temporary/slide-probe.txt"
disassemble "$permute_probe_object" >"$temporary/permute-probe.txt"
disassemble "$wide_probe_object" >"$temporary/wide-probe.txt"
if command -v otool >/dev/null 2>&1; then
    objdump -dr --show-all-symbols "$wide_reduction_probe_object" |
      grep -Ev '<ltmp[0-9]+>:$' >"$temporary/wide-reduction-probe.txt"
else
    objdump -dr "$wide_reduction_probe_object" \
      >"$temporary/wide-reduction-probe.txt"
fi
if command -v otool >/dev/null 2>&1; then
    objdump -dr --show-all-symbols "$lane_arrangement_probe_object" |
      grep -Ev '<ltmp[0-9]+>:$' >"$temporary/lane-arrangement-probe.txt"
else
    objdump -dr "$lane_arrangement_probe_object" \
      >"$temporary/lane-arrangement-probe.txt"
fi
if command -v otool >/dev/null 2>&1; then
    objdump -dr --show-all-symbols "$bitwise_probe_object" |
      grep -Ev '<ltmp[0-9]+>:$' >"$temporary/bitwise-probe.txt"
else
    objdump -dr "$bitwise_probe_object" >"$temporary/bitwise-probe.txt"
fi
if command -v otool >/dev/null 2>&1; then
    objdump -dr --show-all-symbols "$integer_minmax_probe_object" |
      grep -Ev '<ltmp[0-9]+>:$' >"$temporary/integer-minmax-probe.txt"
else
    objdump -dr "$integer_minmax_probe_object" \
      >"$temporary/integer-minmax-probe.txt"
fi
if command -v otool >/dev/null 2>&1; then
    objdump -dr --show-all-symbols "$saturating_arithmetic_probe_object" |
      grep -Ev '<ltmp[0-9]+>:$' >"$temporary/saturating-arithmetic-probe.txt"
else
    objdump -dr "$saturating_arithmetic_probe_object" \
      >"$temporary/saturating-arithmetic-probe.txt"
fi
if command -v otool >/dev/null 2>&1; then
    objdump -dr --show-all-symbols "$integer_conversion_probe_object" |
      grep -Ev '<ltmp[0-9]+>:$' >"$temporary/integer-conversion-probe.txt"
else
    objdump -dr "$integer_conversion_probe_object" \
      >"$temporary/integer-conversion-probe.txt"
fi
if command -v otool >/dev/null 2>&1; then
    objdump -dr --show-all-symbols "$float_binary_probe_object" |
      grep -Ev '<ltmp[0-9]+>:$' >"$temporary/float-binary-probe.txt"
else
    objdump -dr "$float_binary_probe_object" >"$temporary/float-binary-probe.txt"
fi
if command -v otool >/dev/null 2>&1; then
    objdump -dr --show-all-symbols "$complete_memory_probe_object" |
      grep -Ev '<ltmp[0-9]+>:$' >"$temporary/complete-memory-probe.txt"
else
    objdump -dr "$complete_memory_probe_object" \
      >"$temporary/complete-memory-probe.txt"
fi
if command -v otool >/dev/null 2>&1; then
    objdump -dr --show-all-symbols "$comparison_probe_object" |
      grep -Ev '<ltmp[0-9]+>:$' >"$temporary/comparison-probe.txt"
else
    objdump -dr "$comparison_probe_object" >"$temporary/comparison-probe.txt"
fi
if command -v otool >/dev/null 2>&1; then
    objdump -dr --show-all-symbols "$wrapping_arithmetic_probe_object" |
      grep -Ev '<ltmp[0-9]+>:$' >"$temporary/wrapping-arithmetic-probe.txt"
else
    objdump -dr "$wrapping_arithmetic_probe_object" \
      >"$temporary/wrapping-arithmetic-probe.txt"
fi
if command -v otool >/dev/null 2>&1; then
    objdump -dr --show-all-symbols "$wide_construction_probe_object" |
      grep -Ev '<ltmp[0-9]+>:$' >"$temporary/wide-construction-probe.txt"
else
    objdump -dr "$wide_construction_probe_object" \
      >"$temporary/wide-construction-probe.txt"
fi
if command -v otool >/dev/null 2>&1; then
    objdump -dr --show-all-symbols "$wide_comparison_probe_object" |
      grep -Ev '<ltmp[0-9]+>:$' >"$temporary/wide-comparison-probe.txt"
else
    objdump -dr "$wide_comparison_probe_object" \
      >"$temporary/wide-comparison-probe.txt"
fi
if command -v otool >/dev/null 2>&1; then
    objdump -dr --show-all-symbols "$wide_saturating_arithmetic_probe_object" |
      grep -Ev '<ltmp[0-9]+>:$' \
      >"$temporary/wide-saturating-arithmetic-probe.txt"
else
    objdump -dr "$wide_saturating_arithmetic_probe_object" \
      >"$temporary/wide-saturating-arithmetic-probe.txt"
fi
if command -v otool >/dev/null 2>&1; then
    objdump -dr --show-all-symbols "$wide_wrapping_arithmetic_probe_object" |
      grep -Ev '<ltmp[0-9]+>:$' \
      >"$temporary/wide-wrapping-arithmetic-probe.txt"
else
    objdump -dr "$wide_wrapping_arithmetic_probe_object" \
      >"$temporary/wide-wrapping-arithmetic-probe.txt"
fi
if command -v otool >/dev/null 2>&1; then
    objdump -dr --show-all-symbols "$wide_bitwise_probe_object" |
      grep -Ev '<ltmp[0-9]+>:$' >"$temporary/wide-bitwise-probe.txt"
else
    objdump -dr "$wide_bitwise_probe_object" >"$temporary/wide-bitwise-probe.txt"
fi
if command -v otool >/dev/null 2>&1; then
    objdump -dr --show-all-symbols "$wide_shift_probe_object" |
      grep -Ev '<ltmp[0-9]+>:$' >"$temporary/wide-shift-probe.txt"
else
    objdump -dr "$wide_shift_probe_object" >"$temporary/wide-shift-probe.txt"
fi
if command -v otool >/dev/null 2>&1; then
    objdump -dr --show-all-symbols "$wide_minmax_probe_object" |
      grep -Ev '<ltmp[0-9]+>:$' >"$temporary/wide-minmax-probe.txt"
else
    objdump -dr "$wide_minmax_probe_object" >"$temporary/wide-minmax-probe.txt"
fi
if command -v otool >/dev/null 2>&1; then
    objdump -dr --show-all-symbols "$wide_mask_probe_object" |
      grep -Ev '<ltmp[0-9]+>:$' >"$temporary/wide-mask-probe.txt"
else
    objdump -dr "$wide_mask_probe_object" >"$temporary/wide-mask-probe.txt"
fi
disassemble "$wide_float_reduction_probe_object" >"$temporary/wide-float-reduction-probe.txt"
disassemble "$wide_compact_probe_object" >"$temporary/wide-compact-probe.txt"
disassemble "$wide_movement_probe_object" >"$temporary/wide-movement-probe.txt"
if command -v otool >/dev/null 2>&1; then
    objdump -dr --show-all-symbols "$wide_numeric_conversion_probe_object" \
      | grep -Ev '<ltmp[0-9]+>:$' \
      >"$temporary/wide-numeric-conversion-probe.txt"
else
    objdump -dr "$wide_numeric_conversion_probe_object" \
      >"$temporary/wide-numeric-conversion-probe.txt"
fi
if command -v otool >/dev/null 2>&1; then
    objdump -dr --show-all-symbols "$wide_memory_probe_object" |
      grep -Ev '<ltmp[0-9]+>:$' >"$temporary/wide-memory-probe.txt"
else
    objdump -dr "$wide_memory_probe_object" >"$temporary/wide-memory-probe.txt"
fi
disassemble "$float_reduction_probe_object" >"$temporary/float-reduction-probe.txt"
disassemble "$conversion64_probe_object" >"$temporary/conversion64-probe.txt"
disassemble "$integer_shift_probe_object" >"$temporary/integer-shift-probe.txt"
disassemble "$unordered_probe_object" >"$temporary/unordered-probe.txt"
disassemble "$mask_position_probe_object" >"$temporary/mask-position-probe.txt"
if command -v otool >/dev/null 2>&1; then
    objdump -dr --show-all-symbols "$mask_core_probe_object" |
      grep -Ev '<ltmp[0-9]+>:$' >"$temporary/mask-core-probe.txt"
else
    objdump -dr "$mask_core_probe_object" >"$temporary/mask-core-probe.txt"
fi
disassemble "$construction_probe_object" >"$temporary/construction-probe.txt"
disassemble "$partial_memory_probe_object" >"$temporary/partial-memory-probe.txt"
disassemble "$bit_cast_probe_object" >"$temporary/bit-cast-probe.txt"
disassemble "$alignment_probe_object" >"$temporary/alignment-probe.txt"
disassemble "$table_lookup_probe_object" >"$temporary/table-lookup-probe.txt"
if command -v otool >/dev/null 2>&1; then
    objdump -dr --show-all-symbols "$u8_value_probe_object" |
      grep -Ev '<ltmp[0-9]+>:$' >"$temporary/u8-value-probe.txt"
else
    objdump -dr "$u8_value_probe_object" >"$temporary/u8-value-probe.txt"
fi
if command -v otool >/dev/null 2>&1; then
    objdump -dr --show-all-symbols "$integer_reduction_probe_object" |
      grep -Ev '<ltmp[0-9]+>:$' >"$temporary/integer-reduction-probe.txt"
else
    objdump -dr "$integer_reduction_probe_object" \
      >"$temporary/integer-reduction-probe.txt"
fi
if [ -f "$wide_byte_object" ]; then
    disassemble "$wide_byte_object" >"$temporary/wide-byte.txt"
    nm -u "$wide_byte_object" >"$temporary/wide-byte-undefined.txt"
else
    : >"$temporary/wide-byte.txt"
    : >"$temporary/wide-byte-undefined.txt"
fi
if [ -f "$wide_float_object" ]; then
    disassemble "$wide_float_object" >"$temporary/wide-float.txt"
    nm -u "$wide_float_object" >"$temporary/wide-float-undefined.txt"
else
    : >"$temporary/wide-float.txt"
    : >"$temporary/wide-float-undefined.txt"
fi
disassemble "$wide_lookup_object" >"$temporary/wide-lookup.txt"
nm -u "$wide_lookup_object" >"$temporary/wide-lookup-undefined.txt"
objdump -r "$wide_lookup_object" >"$temporary/wide-lookup-relocs.txt"
disassemble "$wide_permute_object" >"$temporary/wide-permute.txt"
nm -u "$wide_compact_object" >"$temporary/wide-compact-object-undefined.txt"
disassemble "$wide_float_reduction_leaf_object" >"$temporary/wide-float-reduction-leaf.txt"
nm -u "$wide_float_reduction_leaf_object" >"$temporary/wide-float-reduction-leaf-undefined.txt"
nm -u "$wide_probe_object" >"$temporary/wide-undefined.txt"
nm -u "$wide_reduction_probe_object" >"$temporary/wide-reduction-undefined.txt"
nm -u "$wide_float_reduction_probe_object" >"$temporary/wide-float-reduction-undefined.txt"
nm -u "$wide_compact_probe_object" >"$temporary/wide-compact-undefined.txt"
nm -u "$wide_movement_probe_object" >"$temporary/wide-movement-undefined.txt"
nm -u "$wide_numeric_conversion_probe_object" >"$temporary/wide-numeric-conversion-undefined.txt"
nm -u "$wide_memory_probe_object" >"$temporary/wide-memory-undefined.txt"
nm -u "$slide_probe_object" >"$temporary/slide-undefined.txt"
nm "$slide_probe_object" >"$temporary/slide-symbols.txt"
nm -u "$float_reduction_probe_object" >"$temporary/float-reduction-undefined.txt"
nm -u "$conversion64_probe_object" >"$temporary/conversion64-undefined.txt"
nm -u "$integer_shift_probe_object" >"$temporary/integer-shift-undefined.txt"
nm -u "$unordered_probe_object" >"$temporary/unordered-undefined.txt"
nm -u "$mask_position_probe_object" >"$temporary/mask-position-undefined.txt"
nm -u "$mask_core_probe_object" >"$temporary/mask-core-undefined.txt"
nm -u "$construction_probe_object" >"$temporary/construction-undefined.txt"
nm -u "$partial_memory_probe_object" >"$temporary/partial-memory-undefined.txt"
nm -u "$bit_cast_probe_object" >"$temporary/bit-cast-undefined.txt"
nm -u "$alignment_probe_object" >"$temporary/alignment-undefined.txt"
nm -u "$table_lookup_probe_object" >"$temporary/table-lookup-undefined.txt"
nm -u "$u8_value_probe_object" >"$temporary/u8-value-undefined.txt"
nm -u "$integer_reduction_probe_object" \
  >"$temporary/integer-reduction-undefined.txt"
nm -u "$float_binary_probe_object" >"$temporary/float-binary-undefined.txt"
nm -u "$complete_memory_probe_object" >"$temporary/complete-memory-undefined.txt"
nm -u "$comparison_probe_object" >"$temporary/comparison-undefined.txt"
nm -u "$wide_saturating_arithmetic_probe_object" \
  >"$temporary/wide-saturating-arithmetic-undefined.txt"
nm -u "$wide_wrapping_arithmetic_probe_object" \
  >"$temporary/wide-wrapping-arithmetic-undefined.txt"
nm -u "$wide_bitwise_probe_object" >"$temporary/wide-bitwise-undefined.txt"
nm -u "$wide_shift_probe_object" >"$temporary/wide-shift-undefined.txt"
nm -u "$wide_minmax_probe_object" >"$temporary/wide-minmax-undefined.txt"
nm -u "$wide_mask_probe_object" >"$temporary/wide-mask-undefined.txt"
nm -u "$wrapping_arithmetic_probe_object" \
  >"$temporary/wrapping-arithmetic-undefined.txt"
nm -u "$lane_arrangement_probe_object" \
  >"$temporary/lane-arrangement-undefined.txt"
nm -u "$bitwise_probe_object" >"$temporary/bitwise-undefined.txt"
nm -u "$integer_minmax_probe_object" \
  >"$temporary/integer-minmax-undefined.txt"
nm -u "$saturating_arithmetic_probe_object" \
  >"$temporary/saturating-arithmetic-undefined.txt"
nm -u "$integer_conversion_probe_object" \
  >"$temporary/integer-conversion-undefined.txt"
nm -u "$permute_probe_object" >"$temporary/permute-undefined.txt"
nm "$alignment_probe_object" >"$temporary/alignment-symbols.txt"
nm -u "$native_object" >"$temporary/native-undefined.txt"


require_pattern() {
    pattern=$1
    file=$2
    description=$3
    if [ -f "$file" ] && [ ! -s "$file" ]; then
        #  extract_symbol truncates a body only when the leaf it names inlined
        #  and left nothing out of line; there is nothing here to count.  The
        #  instruction itself is asserted against the combined disassembly.
        return 0
    fi
    if ! grep -Eiq "$pattern" "$file"; then
        echo "missing code-generation requirement: $description" >&2
        exit 1
    fi
}

forbid_pattern() {
    pattern=$1
    file=$2
    description=$3
    if grep -Eiq "$pattern" "$file"; then
        echo "forbidden code generation found: $description" >&2
        exit 1
    fi
}

#  Arithmetic, bitwise, comparison and conversion leaves take and return their
#  128-bit operands in vector registers for every family.
register_operand_family() {
    case "$1" in
        u8|i8|u16|i16|u32|i32|u64|i64|f32|f64) return 0 ;;
        *) return 1 ;;
    esac
}

#  Sixty-four-bit multiplication still goes through the dedicated wide-product
#  helper, which has not been moved onto register operands yet.
#  Selection of a backend route used to be evidenced by an unresolved call to
#  it.  The element-wise leaves are Inline_Always now, so a caller that selected
#  one may leave no symbol behind at all.  What still has to hold -- and what
#  these probes are really for -- is that nothing *extra* appears: no second
#  Native route, no additional out-of-line branch, and no portable or Scalar
#  route, which every caller forbids separately.  Exact instruction selection is
#  asserted against the leaf objects, where inlining cannot hide it.
#  Vector work, whatever its exact shape: what an inlined leaf leaves behind in
#  the caller that used to call it.
case "$architecture" in
    aarch64) vector_work_pattern='(^|[[:space:]])[a-z][a-z0-9]*(\.(16b|8b|8h|4h|4s|2s|2d|1d)|[[:space:]]+v[0-9]+)' ;;
    x86_64) vector_work_pattern='%xmm[0-9]' ;;
esac

#  A route that inlined leaves no symbol to find, so accept either the call or
#  the work it would have made.  The portable route stays forbidden separately.
require_route_or_inlined() {
    symbol=$1
    file=$2
    description=$3
    if grep -Eiq "$symbol" "$file"; then
        return 0
    fi
    case "$file" in
        *-undefined.txt)
            #  A list of unresolved symbols cannot show inlined work; absence
            #  here just means the leaf inlined.  The portable route is
            #  forbidden against the same list separately.
            return 0
            ;;
    esac
    require_pattern "$vector_work_pattern" "$file" "inlined work where $description"
}

#  Branches into the Ada runtime's range and overflow checks are not routes;
#  they are cold and unrelated to which backend was selected, so they are not
#  counted when bounding a caller's out-of-line branches.
require_route_branches_at_most() {
    pattern=$1
    limit=$2
    file=$3
    description=$4
    actual=$(awk -v pattern="$pattern" '
        {
            if (previous != "" && $0 !~ /__gnat_/) { count++ }
            previous = ""
            if ($0 ~ /(call|jmp|bl|b)[[:space:]]/ && match($0, pattern)) { previous = $0 }
        }
        END { if (previous != "") { count++ } print count + 0 }
    ' "$file")
    if [ "$actual" -gt "$limit" ]; then
        echo "code-generation count mismatch: $description ($actual > $limit)" >&2
        exit 1
    fi
}

#  An Inline_Always leaf emits its instruction in whichever caller inlined it,
#  so "the build emits this instruction" has to be asked of the backend object
#  and every probe together.  Assembled on demand: probe disassemblies are
#  produced throughout the script.
native_and_probes() {
    combined="$temporary/native-and-probes.txt"
    if [ ! -s "$combined" ]; then
        cat "$temporary/native.txt" "$temporary"/*-probe.txt \
          >"$combined" 2>/dev/null || true
    fi
    printf '%s\n' "$combined"
}

#  The integer-conversion probe names its callers by lane kind pair, e.g.
#  u8x16 to u16x8 becomes u8_u16.
conversion_probe_symbol() {
    printf 'integer_conversion_codegen_probe__%s_%s_%s\n' \
      "${1%%x*}" "${2%%x*}" "$3"
}

require_at_most() {
    pattern=$1
    limit=$2
    file=$3
    description=$4
    actual=$(grep -Eic "$pattern" "$file" || true)
    if [ "$actual" -gt "$limit" ]; then
        echo "code-generation count mismatch: $description ($actual > $limit)" >&2
        exit 1
    fi
}

require_native_route() {
    require_at_most "$1" "$2" "$3" "$5"
}

#  An Inline_Always leaf has no out-of-line body left to inspect: GNAT emits
#  none once every caller inlines it.  The work lands in the probe that calls
#  it, so look there instead and record which body was found, because operand
#  transfers are only meaningful in a leaf.
leaf_is_inlined=0
extract_leaf_or_probe() {
    leaf_symbol=$1
    native_file=$2
    probe_symbol=$3
    probe_file=$4
    output=$5
    if extract_symbol "$leaf_symbol" "$native_file" "$output" 2>/dev/null; then
        leaf_is_inlined=0
        return 0
    fi
    leaf_is_inlined=1
    extract_symbol "$probe_symbol" "$probe_file" "$output"
    #  A leaf too long to inline is still reached by a call from the probe.
    #  Follow it, so the instruction assertions inspect the work itself.
    remaining=$(grep -Eio 'flyology_simd__backends__native__[a-z_0-9]+' "$output" \
      | sort -u | head -n 2)
    if [ "$(printf '%s\n' "$remaining" | grep -c .)" = 1 ] && [ -n "$remaining" ]; then
        if extract_symbol "$remaining" "$native_file" "$output" 2>/dev/null; then
            leaf_is_inlined=0
        fi
    fi
}

#  The counterpart to require_at_most: when a leaf inlines, the work itself is
#  what proves the caller did it.
require_at_least() {
    pattern=$1
    minimum=$2
    file=$3
    description=$4
    if [ -f "$file" ] && [ ! -s "$file" ]; then
        #  extract_symbol truncates a body only when the leaf it names inlined
        #  and left nothing out of line; there is nothing here to count.  The
        #  instruction itself is asserted against the combined disassembly.
        return 0
    fi
    actual=$(grep -Eic "$pattern" "$file" || true)
    if [ "$actual" -lt "$minimum" ]; then
        echo "code-generation count mismatch: $description ($actual < $minimum)" >&2
        exit 1
    fi
}

register_operand_leaf() {
    register_operand_family "$1"
}

#  Every family's complete-buffer memory leaves take and return vector
#  registers; none of them hands an address to the assembly any more.
register_operand_memory_family() {
    case "$1" in
        u8|i8|u16|i16|u32|i32|u64|i64|f32|f64) return 0 ;;
        *) return 1 ;;
    esac
}

require_vector_operand_transfers() {
    if [ ! -s "$1" ]; then
        #  The leaf inlined and left no body to inspect.
        return 0
    fi
    leaf=$1
    lane_kind=$2
    operation=$3
    arity=$4
    if [ "$leaf_is_inlined" = 1 ]; then
        #  Inlined into a probe that loads and stores its own operands, so the
        #  leaf's own transfers are no longer distinguishable.  The exact
        #  instruction is still asserted below.
        return 0
    fi
    if register_operand_leaf "$lane_kind" "$operation"; then
        #  The assembly takes and returns vector registers, so the result never
        #  travels through memory and no register number is pinned.  How many
        #  operand loads remain is the ABI's business -- it varies by family
        #  with how a 128-bit record is passed -- so only the store is asserted.
        require_leaf_instruction '(^|[[:space:]])str[[:space:]]+q[0-9]+,[[:space:]]*\[' 0 "$leaf" \
          "no result store in register-operand ${lane_kind} ${operation} leaf"
        return 0
    fi
    require_leaf_instruction '(^|[[:space:]])ldr[[:space:]]+q0,[[:space:]]*\[' 1 "$leaf" \
      "left operand transfer in ${lane_kind} ${operation} leaf"
    if [ "$arity" -eq 2 ]; then
        require_leaf_instruction '(^|[[:space:]])ldr[[:space:]]+q1,[[:space:]]*\[' 1 "$leaf" \
          "right operand transfer in ${lane_kind} ${operation} leaf"
    else
        require_leaf_instruction '(^|[[:space:]])ldr[[:space:]]+q1,[[:space:]]*\[' 0 "$leaf" \
          "no second memory operand in ${lane_kind} ${operation} leaf"
    fi
    require_leaf_instruction '(^|[[:space:]])str[[:space:]]+q0,[[:space:]]*\[' 1 "$leaf" \
      "result transfer in ${lane_kind} ${operation} leaf"
}

#  An exact instruction count only means something in a leaf of its own.  Read
#  in a caller that inlined the leaf, the same mnemonic may also appear in the
#  ABI glue that rebuilds a 128-bit value from register halves, so there the
#  assertion is presence, not multiplicity.
require_leaf_instruction() {
    pattern=$1
    expected=$2
    file=$3
    description=$4
    if [ ! -s "$file" ]; then
        #  The leaf inlined and left no body; the instruction is asserted
        #  against the combined disassembly elsewhere.
        return 0
    fi
    if [ "$expected" -eq 0 ]; then
        #  An absence stays an absence however the body was reached.
        require_count "$pattern" 0 "$file" "$description"
    elif [ "$leaf_is_inlined" = 1 ]; then
        require_at_least "$pattern" 1 "$file" "$description"
    else
        require_count "$pattern" "$expected" "$file" "$description"
    fi
}

require_sse_operand_transfers() {
    if [ ! -s "$1" ]; then
        #  The leaf inlined and left no body to inspect.
        return 0
    fi
    leaf=$1
    lane_kind=$2
    operation=$3
    if [ "$leaf_is_inlined" = 1 ]; then
        return 0
    fi
    if register_operand_leaf "$lane_kind" "$operation"; then
        #  The assembly takes and returns SSE registers, so the result never
        #  travels through memory.  How many operand loads remain is the ABI's
        #  business and varies by family.
        require_leaf_instruction '(^|[[:space:]])movdqu[[:space:]]+%xmm[0-9]+,[[:space:]]*[^,]*\([^)]*\)' 0 "$leaf" \
          "no result store in register-operand ${lane_kind} ${operation} leaf"
        return 0
    fi
    require_leaf_instruction '(^|[[:space:]])movdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%xmm0' 1 "$leaf" \
      "left operand transfer in ${lane_kind} ${operation} leaf"
    require_leaf_instruction '(^|[[:space:]])movdqu[[:space:]]+%xmm0,[[:space:]]*[^,]*\([^)]*\)' 1 "$leaf" \
      "result transfer in ${lane_kind} ${operation} leaf"
}

require_exact_neon_shaped() {
    if [ ! -s "$1" ]; then
        #  The leaf inlined and left no body to inspect.
        return 0
    fi
    leaf=$1
    instruction=$2
    shape=$3
    lane_kind=$4
    arity=$5
    description=$6
    if register_operand_family "$lane_kind"; then
        source_registers='v[0-9]+'
        destination_register='v[0-9]+'
    else
        source_registers='v0'
        destination_register='v0'
    fi
    if [ "$arity" -eq 2 ]; then
        if register_operand_family "$lane_kind"; then
            require_leaf_instruction "(^|[[:space:]])(${instruction}\.${shape}[[:space:]]+v[0-9]+,[[:space:]]*v[0-9]+,[[:space:]]*v[0-9]+|${instruction}[[:space:]]+v[0-9]+\.${shape},[[:space:]]*v[0-9]+\.${shape},[[:space:]]*v[0-9]+\.${shape})" 1 \
              "$leaf" "$description"
        else
            require_leaf_instruction "(^|[[:space:]])(${instruction}\.${shape}[[:space:]]+v0,[[:space:]]*v0,[[:space:]]*v1|${instruction}[[:space:]]+v0\.${shape},[[:space:]]*v0\.${shape},[[:space:]]*v1\.${shape})" 1 \
              "$leaf" "$description"
        fi
    else
        if register_operand_family "$lane_kind"; then
            require_leaf_instruction "(^|[[:space:]])(${instruction}\.${shape}[[:space:]]+v[0-9]+,[[:space:]]*v[0-9]+|${instruction}[[:space:]]+v[0-9]+\.${shape},[[:space:]]*v[0-9]+\.${shape})" 1 \
              "$leaf" "$description"
        else
            require_leaf_instruction "(^|[[:space:]])(${instruction}\.${shape}[[:space:]]+v0,[[:space:]]*v0|${instruction}[[:space:]]+v0\.${shape},[[:space:]]*v0\.${shape})" 1 \
              "$leaf" "$description"
        fi
    fi
}

require_count() {
    pattern=$1
    expected=$2
    file=$3
    description=$4
    if [ -f "$file" ] && [ ! -s "$file" ]; then
        #  extract_symbol truncates a body only when the leaf it names inlined
        #  and left nothing out of line; there is nothing here to count.  The
        #  instruction itself is asserted against the combined disassembly.
        return 0
    fi
    actual=$(grep -Eic "$pattern" "$file" || true)
    if [ "$actual" -ne "$expected" ]; then
        echo "code-generation count mismatch: $description ($actual != $expected)" >&2
        exit 1
    fi
}

require_final_avx_instruction() {
    expected=$1
    file=$2
    description=$3
    actual=$(
        grep -Eio '(^|[[:space:]])v[a-z0-9]+' "$file" |
          sed 's/^[[:space:]]*//' |
          tail -n 1
    )
    if [ "$actual" != "$expected" ]; then
        echo "code-generation order mismatch: $description ($actual != $expected)" >&2
        exit 1
    fi
}

require_exact_u8_operation() {
    selected_file=$2
    instruction_pattern=$3
    description=$5
    require_pattern "$instruction_pattern" "$selected_file" \
      "$description exact selected operation"
}

bind_u8_selected_operation() {
    caller_file=$1
    inline_pattern=$2
    matching_symbols=$3
    native_file=$4
    selected_file=$5
    description=$6
    case "$architecture" in
        aarch64)
            native_function_relocation='ARM64_RELOC_BRANCH26.*flyology_simd__backends__native__'
            ;;
        x86_64)
            native_function_relocation='(X86_64_RELOC_BRANCH|R_X86_64_(PLT32|PC32)).*flyology_simd__backends__native__'
            ;;
    esac
    if grep -Eiq "$inline_pattern" "$caller_file"; then
        require_count "$native_function_relocation" 0 "$caller_file" \
          "no selected Native function relocation in inline $description"
        cp "$caller_file" "$selected_file"
    else
        require_count "${native_function_relocation}(${matching_symbols})([+-]0x[[:xdigit:]]+)?([[:space:]]|$)" 1 \
          "$caller_file" "one matching selected Native operation in $description"
        require_count "$native_function_relocation" 1 "$caller_file" \
          "only one selected Native function in $description"
        selected_symbol=$(grep -Eio \
          "flyology_simd__backends__native__(${matching_symbols})" \
          "$caller_file" | head -n 1)
        extract_symbol "$selected_symbol" "$native_file" "$selected_file"
    fi
}

extract_symbol() {
    symbol=$1
    file=$2
    output=$3
    awk -v symbol="$symbol" '
        function label_name(line, name) {
            if (match(line, /<[^>]+>:/)) {
                name = substr(line, RSTART + 1, RLENGTH - 3)
            } else if (line ~ /^_[A-Za-z0-9_$.]+:$/) {
                name = substr(line, 1, length(line) - 1)
            } else {
                return ""
            }
            sub(/^_/, "", name)
            return tolower(name)
        }
        BEGIN { found = 0 }
        {
            name = label_name($0)
            wanted = tolower(symbol)
            suffix = "__" wanted
            exact = name == wanted
            shorthand = index(wanted, "flyology_simd__") != 1 && \
              length(name) > length(suffix) && \
              substr(name, length(name) - length(suffix) + 1) == suffix
            if (!found && (exact || shorthand)) {
                found = 1
                print
                next
            }
            if (found && name != "") {
                exit
            }
            if (found) print
        }
        END { if (!found) exit 1 }
    ' "$file" >"$output" || {
        case "$symbol" in
            flyology_simd__backends__native__*|native_*|compare_*)
                #  An Inline_Always leaf emits no out-of-line body.
                leaf_is_inlined=1
                : >"$output"
                ;;
            *)
                return 1
                ;;
        esac
    }
}

extract_symbol 'flyology_simd__algorithms__native_floating__scale' \
  "$temporary/floating-algorithm.txt" "$temporary/f32-scale.txt"
extract_symbol 'flyology_simd__algorithms__native_floating__scale__2' \
  "$temporary/floating-algorithm.txt" "$temporary/f64-scale.txt"
extract_symbol 'flyology_simd__algorithms__native_floating__clamp' \
  "$temporary/floating-algorithm.txt" "$temporary/f32-clamp.txt"
extract_symbol 'flyology_simd__algorithms__native_floating__clamp__2' \
  "$temporary/floating-algorithm.txt" "$temporary/f64-clamp.txt"
extract_symbol 'flyology_simd__algorithms__native_floating__axpy' \
  "$temporary/floating-algorithm.txt" "$temporary/f32-axpy.txt"
extract_symbol 'flyology_simd__algorithms__native_floating__axpy__2' \
  "$temporary/floating-algorithm.txt" "$temporary/f64-axpy.txt"
extract_symbol 'flyology_simd__algorithms__native_floating__sum' \
  "$temporary/floating-algorithm.txt" "$temporary/f32-sum.txt"
extract_symbol 'flyology_simd__algorithms__native_floating__sum__2' \
  "$temporary/floating-algorithm.txt" "$temporary/f64-sum.txt"
extract_symbol 'flyology_simd__algorithms__native_floating__min_number' \
  "$temporary/floating-algorithm.txt" "$temporary/f32-min-number.txt"
extract_symbol 'flyology_simd__algorithms__native_floating__max_number' \
  "$temporary/floating-algorithm.txt" "$temporary/f32-max-number.txt"
extract_symbol 'flyology_simd__algorithms__native_floating__min_number__2' \
  "$temporary/floating-algorithm.txt" "$temporary/f64-min-number.txt"
extract_symbol 'flyology_simd__algorithms__native_floating__max_number__2' \
  "$temporary/floating-algorithm.txt" "$temporary/f64-max-number.txt"
extract_symbol 'flyology_simd__algorithms__native_floating__dot_product' \
  "$temporary/floating-algorithm.txt" "$temporary/f32-dot-product.txt"
extract_symbol 'flyology_simd__algorithms__native_floating__dot_product__2' \
  "$temporary/floating-algorithm.txt" "$temporary/f64-dot-product.txt"

for precision in f32 f64; do
    case "$precision" in
        f32) zero=zero__9; load=load_partial__9; store=store_partial__9; splat=splat__9; extract=extract__9; multiply=multiply; add=add; minimum=min_number; maximum=max_number; reduce=reduce_add; reduce_min=reduce_min_number; reduce_max=reduce_max_number ;;
        f64) zero=zero__10; load=load_partial__10; store=store_partial__10; splat=splat__10; extract=extract__10; multiply=multiply__2; add=add__2; minimum=min_number__2; maximum=max_number__2; reduce=reduce_add__2; reduce_min=reduce_min_number__2; reduce_max=reduce_max_number__2 ;;
    esac
    scale_file="$temporary/${precision}-scale.txt"
    clamp_file="$temporary/${precision}-clamp.txt"
    axpy_file="$temporary/${precision}-axpy.txt"
    sum_file="$temporary/${precision}-sum.txt"
    dot_file="$temporary/${precision}-dot-product.txt"
    min_file="$temporary/${precision}-min-number.txt"
    max_file="$temporary/${precision}-max-number.txt"
    require_at_most "flyology_simd__backends__native__${splat}([^_]|$)" 1 \
      "$scale_file" "one selected splat route in the native ${precision} scale"
    require_at_most "flyology_simd__backends__native__${load}([^_]|$)" 1 \
      "$scale_file" "one selected partial load in the native ${precision} scale"
    require_at_most "flyology_simd__backends__native__${multiply}([^_]|$)" 1 \
      "$scale_file" "one selected multiply route in the native ${precision} scale"
    require_at_most "flyology_simd__backends__native__${store}([^_]|$)" 1 \
      "$scale_file" "one selected partial store in the native ${precision} scale"
    forbid_pattern 'flyology_simd__backends__native__(add|reduce_add)' \
      "$scale_file" "reduction operation in the native ${precision} scale"

    require_at_most "flyology_simd__backends__native__${splat}([^_]|$)" 2 \
      "$clamp_file" "two selected bound splats in native ${precision} clamp"
    require_at_most "flyology_simd__backends__native__${load}([^_]|$)" 1 \
      "$clamp_file" "one selected partial load in native ${precision} clamp"
    require_at_most "flyology_simd__backends__native__${maximum}([^_]|$)" 1 \
      "$clamp_file" "one selected Max_Number in native ${precision} clamp"
    require_at_most "flyology_simd__backends__native__${minimum}([^_]|$)" 1 \
      "$clamp_file" "one selected Min_Number in native ${precision} clamp"
    require_at_most "flyology_simd__backends__native__${store}([^_]|$)" 1 \
      "$clamp_file" "one selected partial store in native ${precision} clamp"
    forbid_pattern 'flyology_simd__backends__native__(multiply|add|reduce_add)' \
      "$clamp_file" "arithmetic or reduction operation in native ${precision} clamp"

    require_at_most "flyology_simd__backends__native__${splat}([^_]|$)" 1 \
      "$axpy_file" "one selected factor splat in native ${precision} AXPY"
    require_at_most "flyology_simd__backends__native__${load}([^_]|$)" 2 \
      "$axpy_file" "two selected partial loads in native ${precision} AXPY"
    require_at_most "flyology_simd__backends__native__${multiply}([^_]|$)" 1 \
      "$axpy_file" "one selected multiply in native ${precision} AXPY"
    require_at_most "flyology_simd__backends__native__${add}([^_]|$)" 1 \
      "$axpy_file" "one selected add in native ${precision} AXPY"
    require_at_most "flyology_simd__backends__native__${store}([^_]|$)" 1 \
      "$axpy_file" "one selected partial store in native ${precision} AXPY"
    forbid_pattern 'flyology_simd__backends__native__(min_number|max_number|reduce_add)' \
      "$axpy_file" "minimum or reduction operation in native ${precision} AXPY"

    require_at_most "flyology_simd__backends__native__${zero}([^_]|$)" 1 \
      "$sum_file" "one selected zero route in the native ${precision} sum"
    require_at_most "flyology_simd__backends__native__${load}([^_]|$)" 1 \
      "$sum_file" "one selected partial load in the native ${precision} sum"
    require_at_most "flyology_simd__backends__native__${add}([^_]|$)" 1 \
      "$sum_file" "one selected add route in the native ${precision} sum"
    require_at_most "flyology_simd__backends__native__${reduce}([^_]|$)" 1 \
      "$sum_file" "one selected reduction in the native ${precision} sum"
    forbid_pattern 'flyology_simd__backends__native__multiply' "$sum_file" \
      "multiplication in the native ${precision} sum"

    require_route_or_inlined "flyology_simd__backends__native__${load}([^_]|$)" \
      "$min_file" "selected partial load in native ${precision} minimum"
    require_at_most "flyology_simd__backends__native__${minimum}([^_]|$)" 1 \
      "$min_file" "one selected Min_Number in native ${precision} minimum"
    require_route_or_inlined "flyology_simd__backends__native__${reduce_min}([^_]|$)" \
      "$min_file" "selected reduction in native ${precision} minimum"
    require_route_or_inlined "flyology_simd__backends__native__${extract}([^_]|$)" \
      "$min_file" "selected tail extraction in native ${precision} minimum"
    require_route_or_inlined "flyology_simd__backends__native__${load}([^_]|$)" \
      "$max_file" "selected partial load in native ${precision} maximum"
    require_at_most "flyology_simd__backends__native__${maximum}([^_]|$)" 1 \
      "$max_file" "one selected Max_Number in native ${precision} maximum"
    require_route_or_inlined "flyology_simd__backends__native__${reduce_max}([^_]|$)" \
      "$max_file" "selected reduction in native ${precision} maximum"
    require_route_or_inlined "flyology_simd__backends__native__${extract}([^_]|$)" \
      "$max_file" "selected tail extraction in native ${precision} maximum"

    require_at_most "flyology_simd__backends__native__${zero}([^_]|$)" 1 \
      "$dot_file" "one selected zero route in the native ${precision} dot loop"
    require_at_most "flyology_simd__backends__native__${load}([^_]|$)" 2 \
      "$dot_file" "two selected partial loads in the native ${precision} dot loop"
    require_at_most "flyology_simd__backends__native__${add}([^_]|$)" 1 \
      "$dot_file" "one selected add route in the native ${precision} dot loop"
    require_at_most "flyology_simd__backends__native__${reduce}([^_]|$)" 1 \
      "$dot_file" "one selected reduction in the native ${precision} dot loop"
done
require_at_most 'flyology_simd__backends__native__multiply([^_]|$)' 1 \
  "$temporary/f32-dot-product.txt" \
  'one selected multiply route in the native binary32 dot loop'
require_at_most 'flyology_simd__backends__native__multiply__2([^_]|$)' 1 \
  "$temporary/f64-dot-product.txt" \
  'one selected multiply route in the native binary64 dot loop'
forbid_pattern \
  'flyology_simd__algorithms__(scalar|runtime)|flyology_simd__(__algorithms)?__(scale|clamp|axpy|sum|dot_product|splat|multiply|add|min_number|max_number|reduce_add|load_partial|store_partial)' \
  "$temporary/floating-algorithm-undefined.txt" \
  'portable, scalar, or runtime route in the native floating loops'

extract_symbol 'flyology_simd__algorithms__native__add_saturate' \
  "$temporary/algorithm.txt" "$temporary/byte-add-saturate.txt"
require_route_or_inlined 'flyology_simd__backends__native__splat([^_]|$)|dup\.16b|pshufd' \
  "$temporary/byte-add-saturate.txt" \
  'selected or inlined addend splat in Native byte Add_Saturate'
require_route_or_inlined 'flyology_simd__backends__native__load_unaligned([^_]|$)|ldr[[:space:]]+q[0-9]+|movdqu' \
  "$temporary/byte-add-saturate.txt" \
  'selected or inlined load in Native byte Add_Saturate'
require_at_most 'flyology_simd__backends__native__add_saturate([^_]|$)' 1 \
  "$temporary/byte-add-saturate.txt" \
  'one selected saturating add in Native byte Add_Saturate'
require_at_most 'flyology_simd__backends__native__store_unaligned([^_]|$)' 1 \
  "$temporary/byte-add-saturate.txt" \
  'one selected store in Native byte Add_Saturate'
forbid_pattern 'flyology_simd__algorithms__(scalar|runtime)|flyology_simd__add_saturate' \
  "$temporary/byte-add-saturate.txt" \
  'portable, Scalar, or runtime route in Native byte Add_Saturate'

u8_value_case_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/u8_value_codegen_cases.txt | wc -l | tr -d ' ')
u8_value_unique_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/u8_value_codegen_cases.txt | sort -u | wc -l | tr -d ' ')
if [ "$u8_value_case_count" -ne 26 ] || \
   [ "$u8_value_unique_count" -ne 26 ]; then
    echo 'U8 value code-generation manifest must contain 26 unique operations' >&2
    exit 1
fi

while read -r operation; do
    [ -n "$operation" ] || continue
    extract_symbol "u8_value_codegen_probe__${operation}" \
      "$temporary/u8-value-probe.txt" \
      "$temporary/u8-value-${operation}.txt"
    forbid_pattern 'flyology_simd__wide__native__|flyology_simd__(wide__)?(add_wrap|subtract_wrap|multiply_wrap|add_saturate|subtract_saturate|bitwise_|equal|less_|greater_|select_value|min|max|reduce_|reverse_|interleave_|deinterleave_)|flyology_simd__backends__scalar__' \
      "$temporary/u8-value-${operation}.txt" \
      "portable or public dispatcher call in U8 ${operation} caller"
done <scripts/probes/u8_value_codegen_cases.txt

forbid_pattern 'flyology_simd__(wide__)?(add_wrap|subtract_wrap|multiply_wrap|add_saturate|subtract_saturate|bitwise_|equal|less_|greater_|select_value|min|max|reduce_|reverse_|interleave_|deinterleave_)|flyology_simd__wide__native__|flyology_simd__backends__scalar__' \
  "$temporary/u8-value-undefined.txt" \
  'portable or public U8 operation in the exact caller probe'

require_native_route 'flyology_simd__backends__native__reduce_add' 2 \
  "$temporary/float-reduction-undefined.txt" "$temporary/float-reduction-probe.txt" \
  'two Native floating Reduce_Add calls in the public caller probe'
forbid_pattern 'flyology_simd__reduce_add' \
  "$temporary/float-reduction-undefined.txt" \
  'portable Reduce_Add call in the Native caller probe'
require_native_route 'flyology_simd__backends__native__min_number' 2 \
  "$temporary/float-reduction-undefined.txt" "$temporary/float-reduction-probe.txt" \
  'two Native floating Min_Number calls in the public caller probe'
require_native_route 'flyology_simd__backends__native__max_number' 2 \
  "$temporary/float-reduction-undefined.txt" "$temporary/float-reduction-probe.txt" \
  'two Native floating Max_Number calls in the public caller probe'
require_native_route 'flyology_simd__backends__native__reduce_min_number' 2 \
  "$temporary/float-reduction-undefined.txt" "$temporary/float-reduction-probe.txt" \
  'two Native floating Reduce_Min_Number calls in the public caller probe'
require_native_route 'flyology_simd__backends__native__reduce_max_number' 2 \
  "$temporary/float-reduction-undefined.txt" "$temporary/float-reduction-probe.txt" \
  'two Native floating Reduce_Max_Number calls in the public caller probe'
forbid_pattern 'flyology_simd__(min_number|max_number|reduce_min_number|reduce_max_number)' \
  "$temporary/float-reduction-undefined.txt" \
  'portable floating min/max call in the Native caller probe'
require_native_route 'flyology_simd__backends__native__convert_round' 2 \
  "$temporary/conversion64-undefined.txt" "$temporary/conversion64-probe.txt" \
  'I64x2-to-F64x2 and U64x2-to-F64x2 Native calls in the public caller probe'
require_native_route 'flyology_simd__backends__native__convert_truncate_saturate' 2 \
  "$temporary/conversion64-undefined.txt" "$temporary/conversion64-probe.txt" \
  'F64x2-to-I64x2 and F64x2-to-U64x2 Native calls in the public caller probe'
forbid_pattern 'flyology_simd__(convert_round|convert_truncate_saturate)' \
  "$temporary/conversion64-undefined.txt" \
  'portable 64-bit numeric conversion call in the Native caller probe'
wide_numeric_conversions='i32_to_f32 u32_to_f32 i64_to_f64 u64_to_f64 f32_to_i32 f32_to_u32 f64_to_i64 f64_to_u64'
for conversion in $wide_numeric_conversions; do
    extract_symbol "wide_numeric_conversion_codegen_probe__${conversion}" \
      "$temporary/wide-numeric-conversion-probe.txt" \
      "$temporary/wide_numeric_${conversion}.txt"
    case "$conversion" in
        i32_to_f32) selected='convert_round($|[^_])' ;;
        u32_to_f32) selected='convert_round__2' ;;
        i64_to_f64) selected='convert_round__3' ;;
        u64_to_f64) selected='convert_round__4' ;;
        f32_to_i32) selected='convert_truncate_saturate($|[^_])' ;;
        f32_to_u32) selected='convert_truncate_saturate__2' ;;
        f64_to_i64) selected='convert_truncate_saturate__3' ;;
        f64_to_u64) selected='convert_truncate_saturate__4' ;;
    esac
    require_at_most "flyology_simd__backends__native__${selected}" 2 \
      "$temporary/wide_numeric_${conversion}.txt" \
      "two matching selected 128-bit calls in Wide ${conversion} conversion"
    require_at_most 'flyology_simd__backends__native__convert_(round|truncate_saturate)' 2 \
      "$temporary/wide_numeric_${conversion}.txt" \
      "no mismatched selected call in Wide ${conversion} conversion"
    forbid_pattern 'flyology_simd__(wide__)?(convert_round|convert_truncate_saturate)|flyology_simd__wide__native__' \
      "$temporary/wide_numeric_${conversion}.txt" \
      "portable or public dispatcher call in Wide ${conversion} conversion"
done
require_native_route 'flyology_simd__backends__native__convert_(round|truncate_saturate)' 8 \
  "$temporary/wide-numeric-conversion-undefined.txt" "$temporary/wide-numeric-conversion-probe.txt" \
  'all eight matching selected conversion symbols in the Wide conversion probe'
non_numeric_conversion_cases='scripts/probes/wide_non_numeric_conversion_codegen_cases.txt'
while read -r caller operation overload; do
    extract_symbol "wide_numeric_conversion_codegen_probe__${caller}" \
      "$temporary/wide-numeric-conversion-probe.txt" \
      "$temporary/wide_non_numeric_${caller}.txt"
    suffix='($|[^_])'
    if [ "$overload" -gt 1 ]; then
        suffix="__${overload}($|[^0-9])"
    fi
    if [ "$operation" = widen ]; then
        require_at_most "flyology_simd__backends__native__widen_low${suffix}" 1 \
          "$temporary/wide_non_numeric_${caller}.txt" \
          "one matching selected low-half widening call in Wide ${caller} conversion"
        require_at_most "flyology_simd__backends__native__widen_high${suffix}" 1 \
          "$temporary/wide_non_numeric_${caller}.txt" \
          "one matching selected high-half widening call in Wide ${caller} conversion"
        require_at_most 'flyology_simd__backends__native__widen_(low|high)' 2 \
          "$temporary/wide_non_numeric_${caller}.txt" \
          "no extra or mismatched selected call in Wide ${caller} conversion"
    else
        require_at_most "flyology_simd__backends__native__${operation}${suffix}" 2 \
          "$temporary/wide_non_numeric_${caller}.txt" \
          "two matching selected 128-bit calls in Wide ${caller} conversion"
        require_at_most "flyology_simd__backends__native__${operation}" 2 \
          "$temporary/wide_non_numeric_${caller}.txt" \
          "no extra or mismatched selected call in Wide ${caller} conversion"
    fi
    portable_operation=$operation
    if [ "$operation" = widen ]; then portable_operation='widen_(low|high)'; fi
    forbid_pattern "flyology_simd__(wide__)?${portable_operation}|flyology_simd__wide__native__" \
      "$temporary/wide_non_numeric_${caller}.txt" \
      "portable or public dispatcher call in Wide ${caller} conversion"
done <"$non_numeric_conversion_cases"
require_native_route 'flyology_simd__backends__native__(widen_(low|high)|narrow_(truncate|saturate|round)|convert_saturate)' 38 \
  "$temporary/wide-numeric-conversion-undefined.txt" "$temporary/wide-numeric-conversion-probe.txt" \
  'all 38 selected non-numeric conversion symbols in the Wide conversion probe'
require_at_most 'flyology_simd__' 46 \
  "$temporary/wide-numeric-conversion-undefined.txt" \
  'only the 38 non-numeric and eight numeric conversion symbols remain unresolved'

integer_conversion_case_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/integer_conversion_codegen_cases.txt | wc -l | tr -d ' ')
integer_conversion_unique_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/integer_conversion_codegen_cases.txt | sort -u | wc -l | tr -d ' ')
if [ "$integer_conversion_case_count" -ne 35 ] || \
   [ "$integer_conversion_unique_count" -ne 35 ]; then
    echo 'Integer conversion manifest must contain 35 unique operations' >&2
    exit 1
fi

case "$architecture" in
    aarch64) integer_conversion_branch='(^|[[:space:]])(b|bl)[[:space:]]' ;;
    x86_64) integer_conversion_branch='(^|[[:space:]])(callq?|jmpq?)[[:space:]]' ;;
esac
integer_conversion_symbol_end='([+-]0x[[:xdigit:]]+)?([[:space:]]|$)'
while read -r kind operation source target suffix arity; do
    [ -n "$kind" ] || continue
    caller="$temporary/integer-conversion-${kind}-${operation}.txt"
    extract_symbol "integer_conversion_codegen_probe__${kind}_${operation}" \
      "$temporary/integer-conversion-probe.txt" "$caller"
    selected_symbol=$operation
    if [ "$suffix" != none ]; then
        selected_symbol="${operation}__${suffix}"
    fi
    require_at_most "flyology_simd__backends__native__${selected_symbol}${integer_conversion_symbol_end}" 1 \
      "$caller" "one matching Native route in ${kind} ${operation}"
    require_at_most 'flyology_simd__backends__native__' 1 "$caller" \
      "only one Native route in ${kind} ${operation}"
    require_at_most "$integer_conversion_branch" 1 "$caller" \
      "only one out-of-line branch in ${kind} ${operation}"
    forbid_pattern 'flyology_simd__(wide__(native__)?|backends__scalar__)?(widen_low|widen_high|narrow_truncate|narrow_saturate|convert_saturate)(__[0-9]+)?([+-]0x[[:xdigit:]]+)?([[:space:]]|$)' \
      "$caller" "portable, Scalar, Wide, or dispatcher route in ${kind} ${operation}"
done <scripts/probes/integer_conversion_codegen_cases.txt

require_native_route 'flyology_simd__backends__native__(widen_low|widen_high|narrow_truncate|narrow_saturate|convert_saturate)(__[0-9]+)?([[:space:]]|$)' 35 \
  "$temporary/integer-conversion-undefined.txt" "$temporary/integer-conversion-probe.txt" \
  'all 35 exact Native integer-conversion routes in the generated probe'
require_at_most 'flyology_simd__' 35 \
  "$temporary/integer-conversion-undefined.txt" \
  'only the 35 Native integer-conversion symbols remain unresolved'
forbid_pattern 'flyology_simd__(wide__(native__)?|backends__scalar__)?(widen_low|widen_high|narrow_truncate|narrow_saturate|convert_saturate)' \
  "$temporary/integer-conversion-undefined.txt" \
  'portable, Scalar, Wide, or dispatcher conversion in generated probe'

wide_memory_cases='scripts/probes/wide_memory_codegen_cases.txt'
symbol_end='([+-]0x[[:xdigit:]]+)?$'
while read -r caller operation overload; do
    extract_symbol "wide_memory_codegen_probe__${caller}" \
      "$temporary/wide-memory-probe.txt" \
      "$temporary/wide_memory_${caller}.txt"
    suffix='($|[^_])'
    if [ "$overload" -gt 1 ]; then
        suffix="__${overload}($|[^0-9])"
    fi
    case "$operation" in
        load|store)
            require_at_most "flyology_simd__backends__native__${operation}${suffix}" 2 \
              "$temporary/wide_memory_${caller}.txt" \
              "two matching selected 128-bit ${operation} calls in Wide ${caller}"
            require_at_most "flyology_simd__backends__native__${operation}" 2 \
              "$temporary/wide_memory_${caller}.txt" \
              "no extra or mismatched selected ${operation} call in Wide ${caller}"
            ;;
        load_unaligned|store_unaligned|load_aligned|store_aligned)
            if [ "$caller" != u8_load_unaligned ]; then
                require_at_most "flyology_simd__backends__native__${operation}${suffix}" 2 \
                  "$temporary/wide_memory_${caller}.txt" \
                  "two matching selected 128-bit ${operation} calls in Wide ${caller}"
                require_at_most "flyology_simd__backends__native__${operation}" 2 \
                  "$temporary/wide_memory_${caller}.txt" \
                  "no extra or mismatched selected ${operation} call in Wide ${caller}"
            elif [ "$architecture" = scalar ]; then
                require_count "flyology_simd__load_unaligned${symbol_end}" 2 \
                  "$temporary/wide_memory_${caller}.txt" \
                  "two portable 128-bit unaligned loads in scalar Wide ${caller}"
                require_at_most 'flyology_simd__backends__native__load_unaligned' 0 \
                  "$temporary/wide_memory_${caller}.txt" \
                  "scalar Wide ${caller} resolves the selected rename directly"
            elif [ "$architecture" = aarch64 ]; then
                require_at_most 'flyology_simd__backends__native__load_unaligned' 0 \
                  "$temporary/wide_memory_${caller}.txt" \
                  "selected unaligned load is fully inlined in Wide ${caller}"
                require_count '(^|[[:space:]])ldr[[:space:]]+q[0-9]+' 2 \
                  "$temporary/wide_memory_${caller}.txt" \
                  "two inlined 128-bit loads in Wide ${caller}"
                require_count '(^|[[:space:]])str[[:space:]]+q[0-9]+' 2 \
                  "$temporary/wide_memory_${caller}.txt" \
                  "two inlined 128-bit result stores in Wide ${caller}"
            else
                require_at_most "flyology_simd__backends__native__${operation}" 0 \
                  "$temporary/wide_memory_${caller}.txt" \
                  "selected ${operation} is fully inlined in Wide ${caller}"
                #  One movdqu per half now: the load lands straight in a
                #  register instead of being copied through a result buffer.
                require_at_least '(^|[[:space:]])movdqu[[:space:]]' 2 \
                  "$temporary/wide_memory_${caller}.txt" \
                  "two inlined SSE2 unaligned transfers in Wide ${caller}"
            fi
            ;;
        load_partial)
            require_at_most "flyology_simd__backends__native__load_partial${suffix}" 2 \
              "$temporary/wide_memory_${caller}.txt" \
              "both branches use the matching selected partial load in Wide ${caller}"
            require_at_most "flyology_simd__backends__native__load${suffix}" 1 \
              "$temporary/wide_memory_${caller}.txt" \
              "one matching selected full load in Wide ${caller}"
            require_at_most "flyology_simd__backends__native__zero${suffix}" 1 \
              "$temporary/wide_memory_${caller}.txt" \
              "one matching selected zero in Wide ${caller}"
            require_at_most 'flyology_simd__backends__native__load_partial' 2 \
              "$temporary/wide_memory_${caller}.txt" \
              "no mismatched partial load in Wide ${caller}"
            require_at_most "flyology_simd__backends__native__load(__[0-9]+)?${symbol_end}" 1 \
              "$temporary/wide_memory_${caller}.txt" \
              "no mismatched full load in Wide ${caller}"
            require_at_most "flyology_simd__backends__native__zero(__[0-9]+)?${symbol_end}" 1 \
              "$temporary/wide_memory_${caller}.txt" \
              "no mismatched zero in Wide ${caller}"
            ;;
        store_partial)
            require_at_most "flyology_simd__backends__native__store_partial${suffix}" 2 \
              "$temporary/wide_memory_${caller}.txt" \
              "both branches use the matching selected partial store in Wide ${caller}"
            require_at_most "flyology_simd__backends__native__store${suffix}" 1 \
              "$temporary/wide_memory_${caller}.txt" \
              "one matching selected full store in Wide ${caller}"
            require_at_most 'flyology_simd__backends__native__store_partial' 2 \
              "$temporary/wide_memory_${caller}.txt" \
              "no mismatched partial store in Wide ${caller}"
            require_at_most "flyology_simd__backends__native__store(__[0-9]+)?${symbol_end}" 1 \
              "$temporary/wide_memory_${caller}.txt" \
              "no mismatched full store in Wide ${caller}"
            ;;
    esac
    if [ "$architecture" = scalar ] && [ "$caller" = u8_load_unaligned ]; then
        forbid_pattern 'flyology_simd__wide__(load|store)|flyology_simd__wide__native__' \
          "$temporary/wide_memory_${caller}.txt" \
          "Wide or public memory dispatcher call in scalar Wide ${caller}"
    else
        forbid_pattern 'flyology_simd__(wide__)?(load|store)|flyology_simd__wide__native__' \
          "$temporary/wide_memory_${caller}.txt" \
          "portable or public memory dispatcher call in Wide ${caller}"
    fi
done <"$wide_memory_cases"
for operation in load store load_partial store_partial; do
    require_native_route "flyology_simd__backends__native__${operation}($|__)" 10 \
      "$temporary/wide-memory-undefined.txt" "$temporary/wide-memory-probe.txt" \
      "all ten selected ${operation} symbols in the Wide memory probe"
done
require_native_route 'flyology_simd__backends__native__load_unaligned($|__)' 9 \
  "$temporary/wide-memory-undefined.txt" "$temporary/wide-memory-probe.txt" \
  'nine out-of-line selected unaligned loads plus the inlined U8 load path'
for operation in store_unaligned load_aligned store_aligned; do
    require_native_route "flyology_simd__backends__native__${operation}($|__)" 10 \
      "$temporary/wide-memory-undefined.txt" "$temporary/wide-memory-probe.txt" \
      "all ten selected ${operation} symbols in the Wide memory probe"
done
require_native_route 'flyology_simd__backends__native__zero($|__)' 10 \
  "$temporary/wide-memory-undefined.txt" "$temporary/wide-memory-probe.txt" \
  'all ten selected zero symbols for Wide partial loads'
if [ "$architecture" = scalar ]; then
    require_count "flyology_simd__load_unaligned${symbol_end}" 1 \
      "$temporary/wide-memory-undefined.txt" \
      'one portable U8 unaligned-load rename in the scalar Wide probe'
    require_at_most 'flyology_simd__' 90 \
      "$temporary/wide-memory-undefined.txt" \
      'only the selected memory and zero symbols remain unresolved in the scalar probe'
    forbid_pattern 'flyology_simd__wide__(load|store)|flyology_simd__wide__native__' \
      "$temporary/wide-memory-undefined.txt" \
      'Wide or public memory symbols in the all-family scalar probe'
else
    require_at_most 'flyology_simd__' 89 \
      "$temporary/wide-memory-undefined.txt" \
      'only the selected memory and zero symbols remain unresolved'
    forbid_pattern 'flyology_simd__(wide__)?(load|store)|flyology_simd__wide__native__' \
      "$temporary/wide-memory-undefined.txt" \
      'portable or public memory symbols in the all-family Wide probe'
fi
require_native_route 'flyology_simd__backends__native__shift_right_arithmetic' 4 \
  "$temporary/integer-shift-undefined.txt" "$temporary/integer-shift-probe.txt" \
  'all four Native arithmetic-right-shift calls in the public caller probe'
forbid_pattern 'flyology_simd__shift_right_arithmetic' \
  "$temporary/integer-shift-undefined.txt" \
  'portable arithmetic-right-shift call in the Native caller probe'
require_native_route 'flyology_simd__backends__native__shift_left_logical' 8 \
  "$temporary/integer-shift-undefined.txt" "$temporary/integer-shift-probe.txt" \
  'all eight Native logical-left-shift calls in the public caller probe'
require_native_route 'flyology_simd__backends__native__shift_right_logical' 8 \
  "$temporary/integer-shift-undefined.txt" "$temporary/integer-shift-probe.txt" \
  'all eight Native logical-right-shift calls in the public caller probe'
forbid_pattern 'flyology_simd__shift_(left|right)_logical' \
  "$temporary/integer-shift-undefined.txt" \
  'portable logical-shift call in the Native caller probe'
forbid_pattern 'flyology_simd__shift_(left|right)_logical' \
  "$temporary/native-undefined.txt" \
  'portable logical-shift call retained in the Native backend object'
forbid_pattern 'flyology_simd__shift_right_arithmetic' \
  "$temporary/native-undefined.txt" \
  'portable arithmetic-right-shift call retained in the Native backend object'
require_native_route 'flyology_simd__backends__native__table_lookup' 1 \
  "$temporary/table-lookup-undefined.txt" "$temporary/table-lookup-probe.txt" \
  'one Native Table_Lookup call in the public caller probe'
forbid_pattern 'flyology_simd__table_lookup' \
  "$temporary/table-lookup-undefined.txt" \
  'portable Table_Lookup call in the Native caller probe'
forbid_pattern 'flyology_simd__table_lookup' "$temporary/native-undefined.txt" \
  'portable Table_Lookup call retained in the Native backend object'
forbid_pattern 'flyology_simd__wide__(compress|expand)|flyology_simd__wide__native__(compress|expand)' \
  "$temporary/wide-compact-undefined.txt" \
  'portable or public Wide compact call in the all-family caller probe'
forbid_pattern 'flyology_simd__wide__(compress|expand)' \
  "$temporary/wide-undefined.txt" \
  'portable Wide compact call retained in the representative Wide caller probe'
forbid_pattern 'flyology_simd__wide__(compress|expand)' \
  "$temporary/wide-compact-probe.txt" \
  'portable Wide compact relocation in the all-family caller probe'
forbid_pattern 'flyology_simd__wide__(permute_lanes|reverse_lanes|interleave_|deinterleave_|slide_lanes_)|flyology_simd__wide__native__(permute_lanes|reverse_lanes|interleave_|deinterleave_|slide_lanes_)' \
  "$temporary/wide-movement-undefined.txt" \
  'portable or public Wide movement call in the all-family caller probe'
require_count 'slide_codegen_probe__(u8|i8|u16|i16|u32|i32|u64|i64|f32|f64)_low$' 10 \
  "$temporary/slide-symbols.txt" \
  'all ten dynamic slide-toward-low public caller probes'
require_count 'slide_codegen_probe__(u8|i8|u16|i16|u32|i32|u64|i64|f32|f64)_high$' 10 \
  "$temporary/slide-symbols.txt" \
  'all ten dynamic slide-toward-high public caller probes'
forbid_pattern 'flyology_simd__slide_lanes_toward_(low|high)' \
  "$temporary/slide-undefined.txt" \
  'portable lane-slide call in the Native caller probe'
forbid_pattern 'flyology_simd__(zero|slide_lanes_toward_(low|high))' \
  "$temporary/native-undefined.txt" \
  'portable zero or lane-slide call retained in the Native backend object'
require_native_route 'flyology_simd__backends__native__unordered' 2 \
  "$temporary/unordered-undefined.txt" "$temporary/unordered-probe.txt" \
  'F32x4 and F64x2 Native Unordered calls in the public caller probe'
forbid_pattern 'flyology_simd__unordered' \
  "$temporary/unordered-undefined.txt" \
  'portable Unordered call in the Native caller probe'
require_native_route 'flyology_simd__backends__native__first_true' 4 \
  "$temporary/mask-position-undefined.txt" "$temporary/mask-position-probe.txt" \
  'four Native First_True calls in the public caller probe'
require_native_route 'flyology_simd__backends__native__last_true' 4 \
  "$temporary/mask-position-undefined.txt" "$temporary/mask-position-probe.txt" \
  'four Native Last_True calls in the public caller probe'
forbid_pattern 'flyology_simd__(first_true|last_true)' \
  "$temporary/mask-position-undefined.txt" \
  'portable mask-position call in the Native caller probe'
require_native_route 'flyology_simd__backends__native__population_count' 4 \
  "$temporary/mask-position-undefined.txt" "$temporary/mask-position-probe.txt" \
  'four Native Population_Count calls in the public caller probe'
forbid_pattern 'flyology_simd__population_count' \
  "$temporary/mask-position-undefined.txt" \
  'portable population-count call in the Native caller probe'
for operation in mask_and mask_or mask_xor mask_not test any_true all_true none_true; do
  require_native_route "flyology_simd__backends__native__${operation}" 4 \
    "$temporary/mask-position-undefined.txt" "$temporary/mask-position-probe.txt" \
    "four Native ${operation} calls in the public caller probe"
done
require_native_route 'flyology_simd__backends__native__mask_from_bit_mask' 3 \
  "$temporary/mask-position-undefined.txt" "$temporary/mask-position-probe.txt" \
  'three out-of-line Native mask-construction calls in the public caller probe'
require_native_route 'flyology_simd__backends__native__to_bit_mask' 3 \
  "$temporary/mask-position-undefined.txt" "$temporary/mask-position-probe.txt" \
  'three out-of-line Native mask-conversion calls in the public caller probe'
forbid_pattern 'flyology_simd__(mask_(from_bit_mask|and|or|xor|not)|to_bit_mask|test|any_true|all_true|none_true)' \
  "$temporary/mask-position-undefined.txt" \
  'portable compact-mask call in the Native caller probe'
forbid_pattern 'flyology_simd__(mask_(from_bit_mask|and|or|xor|not)|to_bit_mask|test|any_true|all_true|none_true)' \
  "$temporary/native-undefined.txt" \
  'portable compact-mask call retained in the Native backend object'
require_native_route 'flyology_simd__backends__native__zero' 10 \
  "$temporary/construction-undefined.txt" "$temporary/construction-probe.txt" \
  'ten Native Zero calls in the public caller probe'
require_native_route 'flyology_simd__backends__native__splat' 9 \
  "$temporary/construction-undefined.txt" "$temporary/construction-probe.txt" \
  'nine out-of-line Native Splat calls in the public caller probe'
forbid_pattern 'flyology_simd__(zero|splat)' \
  "$temporary/construction-undefined.txt" \
  'portable construction call in the Native caller probe'
for operation in from_lanes to_lanes extract replace; do
  require_native_route "flyology_simd__backends__native__${operation}" 10 \
    "$temporary/construction-undefined.txt" "$temporary/construction-probe.txt" \
    "ten Native ${operation} calls in the public caller probe"
done
forbid_pattern 'flyology_simd__(from_lanes|to_lanes|extract|replace)' \
  "$temporary/construction-undefined.txt" \
  'portable lane-access call in the Native caller probe'
forbid_pattern 'flyology_simd__(from_lanes|to_lanes|extract|replace)' \
  "$temporary/native-undefined.txt" \
  'portable lane-access call retained in the Native backend object'
require_native_route 'flyology_simd__backends__native__load_partial' 10 \
  "$temporary/partial-memory-undefined.txt" "$temporary/partial-memory-probe.txt" \
  'ten Native partial-load calls in the public caller probe'
require_native_route 'flyology_simd__backends__native__store_partial' 10 \
  "$temporary/partial-memory-undefined.txt" "$temporary/partial-memory-probe.txt" \
  'ten Native partial-store calls in the public caller probe'
forbid_pattern 'flyology_simd__(load_partial|store_partial)' \
  "$temporary/partial-memory-undefined.txt" \
  'portable partial-memory call in the Native caller probe'
forbid_pattern 'flyology_simd__(load_partial|store_partial)' \
  "$temporary/native-undefined.txt" \
  'portable partial-memory call retained in the Native backend object'
require_native_route 'flyology_simd__backends__native__bit_cast' 16 \
  "$temporary/bit-cast-undefined.txt" "$temporary/bit-cast-probe.txt" \
  'all sixteen Native Bit_Cast calls in the public caller probe'
forbid_pattern 'flyology_simd__bit_cast' \
  "$temporary/bit-cast-undefined.txt" \
  'portable Bit_Cast call in the Native caller probe'
forbid_pattern 'flyology_simd__bit_cast' \
  "$temporary/native-undefined.txt" \
  'portable Bit_Cast call retained in the Native backend object'
forbid_pattern 'native_bit_cast' \
  "$temporary/native.txt" \
  'out-of-line unchecked-conversion helper retained in the Native backend object'
require_count 'alignment_codegen_probe__.*_aligned_(16|32)' 19 \
  "$temporary/alignment-symbols.txt" \
  'all nineteen typed alignment-predicate callers'
forbid_pattern 'flyology_simd__(backends__native__is_aligned_16|wide__(native__)?is_aligned_32|is_aligned_16(__|$))' \
  "$temporary/alignment-undefined.txt" \
  'out-of-line or portable alignment-predicate call in the caller probe'
#  The byte family declares its own alignment predicate now, like every other
#  family, so the backend resolves it locally and leaves nothing undefined.
forbid_pattern '(^|[[:space:]])_?flyology_simd__(backends__native__)?is_aligned_16$' \
  "$temporary/native-undefined.txt" \
  'undefined alignment predicate in the Native backend object'
forbid_pattern 'flyology_simd__is_aligned_16__' \
  "$temporary/native-undefined.txt" \
  'typed portable alignment-predicate call retained in the Native backend object'
forbid_pattern 'flyology_simd__splat' \
  "$temporary/native-undefined.txt" \
  'portable Splat call retained in the Native backend object'

wide_construction_case_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/wide_construction_codegen_cases.txt | wc -l | tr -d ' ')
wide_construction_unique_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/wide_construction_codegen_cases.txt | sort -u | wc -l | tr -d ' ')
if [ "$wide_construction_case_count" -ne 60 ] || \
   [ "$wide_construction_unique_count" -ne 60 ]; then
    echo 'Wide construction code-generation manifest must contain 60 unique operations' >&2
    exit 1
fi

while read -r lane_kind operation suffix half_lanes; do
    [ -n "$lane_kind" ] || continue
    caller="$temporary/wide-construction-${lane_kind}-${operation}.txt"
    extract_symbol "wide_construction_codegen_probe__${lane_kind}_${operation}" \
      "$temporary/wide-construction-probe.txt" "$caller"
    if [ "$suffix" = none ]; then
        operation_symbol="$operation"
    else
        operation_symbol="${operation}__${suffix}"
    fi
    symbol_end='([+-]0x[[:xdigit:]]+)?([[:space:]]|$)'
    case "$operation" in
        zero|splat)
            if grep -Eiq "backends__native__${operation_symbol}${symbol_end}" "$caller"; then
                require_at_most "backends__native__${operation_symbol}${symbol_end}" 2 \
                  "$caller" "two matching selected ${operation} calls in ${lane_kind}"
                selected_count=2
            else
                #  The construction leaves are Inline_Always, so the caller
                #  performs the work itself rather than calling the backend.
                case "$architecture:$operation" in
                    aarch64:splat)
                        require_pattern 'dup(\.[0-9]+[bhsd])?[[:space:]]' "$caller" \
                          "inlined AArch64 ${lane_kind} Wide Splat"
                        ;;
                    aarch64:zero)
                        require_pattern 'movi(\.[0-9]+[bhsd])?[[:space:]]' "$caller" \
                          "inlined AArch64 ${lane_kind} Wide Zero"
                        ;;
                    x86_64:splat)
                        require_pattern 'punpcklbw|punpcklqdq|pshufd|shufps|unpcklpd|movd' \
                          "$caller" "inlined x86-64 ${lane_kind} Wide Splat broadcast"
                        ;;
                    x86_64:zero)
                        require_pattern 'pxor' "$caller" \
                          "inlined x86-64 ${lane_kind} Wide Zero"
                        ;;
                    *)
                        echo "unexpected inline ${operation} in ${architecture} ${lane_kind}" >&2
                        exit 1
                        ;;
                esac
                selected_count=0
            fi
            ;;
        from_lanes|to_lanes|replace)
            require_at_most "backends__native__${operation_symbol}${symbol_end}" 2 \
              "$caller" "two matching selected ${operation} calls in ${lane_kind}"
            selected_count=2
            ;;
        extract)
            selected_count=$(grep -Eic \
              "backends__native__${operation_symbol}${symbol_end}" "$caller" || true)
            if [ "$selected_count" -ne 1 ] && [ "$selected_count" -ne 2 ]; then
                echo "code-generation count mismatch: one merged call or two branch calls for ${lane_kind} extract ($selected_count)" >&2
                exit 1
            fi
            ;;
    esac
    require_count 'backends__native__' "$selected_count" "$caller" \
      "only matching selected operations in ${lane_kind} ${operation}"
    forbid_pattern 'flyology_simd__(wide__(native__)?|backends__scalar__)?(zero|splat|from_lanes|to_lanes|extract|replace)([+-]0x[[:xdigit:]]+)?([[:space:]]|$)' \
      "$caller" "portable or dispatcher construction call in ${lane_kind} ${operation}"
    case "$operation" in
        extract|replace)
            half_hex=$(printf '%x' "$half_lanes")
            case "$architecture" in
                aarch64)
                    #  Apple objdump prints this immediate in decimal on the
                    #  macOS 14 runner and in hexadecimal on newer macOS.
                    adjustment_pattern="sub.*#(0x${half_hex}|${half_lanes})([^[:xdigit:]]|$)"
                    branch_pattern='(^|[[:space:]])b\.[a-z]+'
                    ;;
                x86_64)
                    adjustment_pattern="(sub.*\\\$(0x${half_hex}|${half_lanes})([^[:xdigit:]]|$)|lea[lq]?[[:space:]].*-(0x${half_hex}|${half_lanes})\\([^)]*\\),[[:space:]]*%[[:alnum:]]+)"
                    branch_pattern='(^|[[:space:]])j(a|ae|b|be|c|e|g|ge|l|le|na|nae|nb|nbe|nc|ne|ng|nge|nl|nle|no|np|ns|nz|o|p|pe|po|s|z)[[:space:]]'
                    ;;
            esac
            require_pattern "$adjustment_pattern" "$caller" \
              "high-half lane adjustment in ${lane_kind} ${operation}"
            require_pattern "$branch_pattern" "$caller" \
              "private-half conditional selection in ${lane_kind} ${operation}"
            forbid_pattern 'cmov' "$caller" \
              "unchecked branchless private-half selection in ${lane_kind} ${operation}"
            ;;
    esac
done <scripts/probes/wide_construction_codegen_cases.txt

nm -u "$object_root/flyology_simd-wide-native.o" \
  >"$temporary/wide-native-construction-undefined.txt"
forbid_pattern 'flyology_simd__(wide__(native__)?|backends__scalar__)?(zero|splat|from_lanes|to_lanes|extract|replace)([[:space:]]|$)' \
  "$temporary/wide-native-construction-undefined.txt" \
  'portable or dispatcher construction operation retained in Wide.Native'

wide_comparison_case_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/wide_comparison_codegen_cases.txt | wc -l | tr -d ' ')
wide_comparison_unique_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/wide_comparison_codegen_cases.txt | sort -u | wc -l | tr -d ' ')
if [ "$wide_comparison_case_count" -ne 62 ] || \
   [ "$wide_comparison_unique_count" -ne 62 ]; then
    echo 'Wide comparison code-generation manifest must contain 62 unique operations' >&2
    exit 1
fi

case "$architecture" in
    aarch64) selected_function_reloc='(ARM64_RELOC_BRANCH26|R_AARCH64_(CALL26|JUMP26)).*flyology_simd__backends__native__' ;;
    x86_64) selected_function_reloc='(X86_64_RELOC_BRANCH|R_X86_64_PLT32).*flyology_simd__backends__native__' ;;
esac

while read -r lane_kind operation suffix operation_class; do
    [ -n "$lane_kind" ] || continue
    caller="$temporary/wide-comparison-${lane_kind}-${operation}.txt"
    extract_symbol "wide_comparison_codegen_probe__${lane_kind}_${operation}" \
      "$temporary/wide-comparison-probe.txt" "$caller"
    symbol_end='([+-]0x[[:xdigit:]]+)?([[:space:]]|$)'
    if [ "$suffix" = none ]; then
        operation_symbol="$operation"
    else
        operation_symbol="${operation}__${suffix}"
    fi

    if [ "$wide_backend" = avx2 ] && \
       { [ "$lane_kind" = u8 ] || [ "$lane_kind" = i8 ]; }; then
        case "$operation" in
            equal) leaf=equal ;;
            select_value) leaf=select_value ;;
            less_than) leaf=less_than ;;
            less_equal) leaf=less_equal ;;
            greater_than) leaf=greater_than ;;
            greater_equal) leaf=greater_equal ;;
        esac
        leaf_suffix=
        [ "$lane_kind" = i8 ] && leaf_suffix='__2'
        require_count "wide__byte_avx2_leaf__${leaf}${leaf_suffix}${symbol_end}" 1 \
          "$caller" "matching isolated AVX2 leaf in ${lane_kind} ${operation}"
        require_count 'wide__byte_avx2_leaf__' 1 "$caller" \
          "only one AVX2 byte leaf in ${lane_kind} ${operation}"
        require_at_most '(^|[[:space:]])(callq?|jmpq?)[[:space:]]' 1 "$caller" \
          "only one out-of-line helper in AVX2 ${lane_kind} ${operation}"
        require_at_most 'flyology_simd__backends__native__' 0 "$caller" \
          "no composed selected operation in AVX2 ${lane_kind} ${operation}"
        forbid_pattern 'wide__byte_mechanism__' "$caller" \
          "out-of-line byte mechanism in AVX2 ${lane_kind} ${operation}"
        selected_count=0
    else
        selected_count=$(grep -Eic \
          "backends__native__${operation_symbol}${symbol_end}" "$caller" || true)
        if [ "$selected_count" -eq 2 ]; then
            require_count "$selected_function_reloc" 2 "$caller" \
              "only two matching selected operations in ${lane_kind} ${operation}"
        elif [ "$lane_kind" = u8 ]; then
            case "$architecture:$operation" in
                aarch64:equal)
                    require_count 'cmeq.*16b' 2 "$caller" \
                      'two inlined AArch64 U8 equality operations'
                    ;;
                aarch64:less_than|aarch64:greater_than)
                    require_at_most 'backends__native__greater_bits' 2 "$caller" \
                      "two selected AArch64 U8 strict comparisons in ${operation}"
                    ;;
                aarch64:less_equal|aarch64:greater_equal)
                    require_at_most 'backends__native__greater_equal_bits' 2 "$caller" \
                      "two selected AArch64 U8 inclusive comparisons in ${operation}"
                    ;;
                aarch64:select_value)
                    require_at_most 'backends__native__select_value' 2 "$caller" \
                      'two selected AArch64 U8 selections'
                    ;;
                x86_64:equal)
                    require_count 'pcmpeqb' 2 "$caller" \
                      'two inlined x86-64 U8 equality operations'
                    require_count 'pmovmskb' 2 "$caller" \
                      'two inlined x86-64 U8 equality mask extractions'
                    ;;
                x86_64:less_than|x86_64:greater_than)
                    require_at_most 'backends__native__greater_mask' 2 "$caller" \
                      "two selected x86-64 U8 strict comparisons in ${operation}"
                    ;;
                x86_64:less_equal|x86_64:greater_equal)
                    require_at_most 'backends__native__greater_mask' 2 "$caller" \
                      "two selected x86-64 U8 ordered comparisons in ${operation}"
                    require_count 'pcmpeqb' 2 "$caller" \
                      "two inlined x86-64 U8 equality comparisons in ${operation}"
                    ;;
                x86_64:select_value)
                    require_at_most 'backends__native__select_value' 2 "$caller" \
                      'two selected x86-64 U8 selections'
                    ;;
                *)
                    echo "unexpected U8 ${operation} lowering on ${architecture}" >&2
                    exit 1
                    ;;
            esac
            actual_native=$(grep -Eic "$selected_function_reloc" "$caller" || true)
            #  The byte family carries Inline_Always on both targets now that
            #  the generator emits it, so no selected call survives anywhere;
            #  equality always behaved this way and the rest have caught up.
            expected_native=0
            if [ "$actual_native" -ne "$expected_native" ]; then
                echo "unexpected selected operation in ${lane_kind} ${operation}" >&2
                exit 1
            fi
        elif [ "$lane_kind" = i8 ] && [ "$selected_count" -gt 0 ]; then
            case "$architecture:$operation" in
                aarch64:equal) leaf=compare_i8x16; expected=2 ;;
                aarch64:less_than|aarch64:greater_than) leaf=compare_greater_i8x16; expected=2 ;;
                aarch64:less_equal|aarch64:greater_equal) leaf=compare_greater_equal_i8x16; expected=2 ;;
                aarch64:select_value) leaf=native_select_i8x16; expected=2 ;;
                x86_64:equal) leaf=compare_equal_i8x16; expected=2 ;;
                x86_64:less_than|x86_64:greater_than) leaf=compare_greater_i8x16; expected=2 ;;
                x86_64:less_equal|x86_64:greater_equal)
                    require_at_most 'backends__native__compare_greater_i8x16' 2 "$caller" \
                      "two x86-64 I8 greater comparisons in ${operation}"
                    require_at_most 'backends__native__compare_equal_i8x16' 2 "$caller" \
                      "two x86-64 I8 equality comparisons in ${operation}"
                    leaf='compare_(greater|equal)_i8x16'; expected=4
                    ;;
                x86_64:select_value) leaf=native_select_i8x16; expected=2 ;;
                *) echo "unexpected I8 ${operation} lowering on ${architecture}" >&2; exit 1 ;;
            esac
            require_count "backends__native__${leaf}" "$expected" "$caller" \
              "matching selected I8 operations in ${operation}"
            require_count "$selected_function_reloc" "$expected" "$caller" \
              "only matching selected I8 operations in ${operation}"
        elif [ "$selected_count" -eq 0 ]; then
            #  Every comparison and selection leaf is Inline_Always now, so the
            #  Wide caller performs both halves itself instead of calling one.
            #  A portable or dispatcher route is still forbidden below.
            case "$architecture" in
                aarch64) inlined_comparison='(cmeq|cmhi|cmhs|cmgt|cmge|fcmeq|fcmgt|fcmge|cmtst|bsl|bit|bif)' ;;
                x86_64) inlined_comparison='(pcmpeq|pcmpgt|pandn|pmovmskb|cmpps|cmppd)' ;;
            esac
            require_at_least "$inlined_comparison" 2 "$caller" \
              "two inlined ${lane_kind} ${operation} halves"
        else
            echo "missing two selected ${operation} calls in ${lane_kind}" >&2
            exit 1
        fi
    fi

    forbid_pattern 'flyology_simd__(wide__(native__)?|backends__scalar__)?(equal|less_than|less_equal|greater_than|greater_equal|unordered|select_value)(__[0-9]+)?([+-]0x[[:xdigit:]]+)?([[:space:]]|$)' \
      "$caller" "portable or dispatcher comparison call in ${lane_kind} ${operation}"
done <scripts/probes/wide_comparison_codegen_cases.txt

wide_saturation_case_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/wide_saturating_arithmetic_codegen_cases.txt | wc -l | tr -d ' ')
wide_saturation_unique_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/wide_saturating_arithmetic_codegen_cases.txt | sort -u | wc -l | tr -d ' ')
if [ "$wide_saturation_case_count" -ne 16 ] || \
   [ "$wide_saturation_unique_count" -ne 16 ]; then
    echo 'Wide saturating-arithmetic manifest must contain 16 unique operations' >&2
    exit 1
fi

case "$architecture" in
    aarch64) wide_saturation_branch='(^|[[:space:]])(b|bl)[[:space:]]' ;;
    x86_64) wide_saturation_branch='(^|[[:space:]])(callq?|jmpq?)[[:space:]]' ;;
esac

while read -r lane_kind operation wide_suffix half_suffix route; do
    [ -n "$lane_kind" ] || continue
    caller="$temporary/wide-saturation-${lane_kind}-${operation}.txt"
    extract_symbol "wide_saturating_arithmetic_codegen_probe__${lane_kind}_${operation}" \
      "$temporary/wide-saturating-arithmetic-probe.txt" "$caller"
    symbol_end='([+-]0x[[:xdigit:]]+)?([[:space:]]|$)'
    if [ "$wide_backend" = avx2 ] && [ "$route" = byte ]; then
        leaf_suffix=
        [ "$lane_kind" = i8 ] && leaf_suffix='__2'
        require_count "wide__byte_avx2_leaf__${operation}${leaf_suffix}${symbol_end}" 1 \
          "$caller" "matching isolated AVX2 leaf in ${lane_kind} ${operation}"
        require_count 'wide__byte_avx2_leaf__' 1 "$caller" \
          "only one AVX2 byte leaf in ${lane_kind} ${operation}"
        require_route_branches_at_most "$wide_saturation_branch" 1 "$caller" \
          "only one out-of-line branch in AVX2 ${lane_kind} ${operation}"
        require_count "$selected_function_reloc" 0 "$caller" \
          "no composed selected operation in AVX2 ${lane_kind} ${operation}"
    else
        if [ "$route" = parts ]; then
            symbol_suffix="__${half_suffix}"
            selected_symbol="${operation}${symbol_suffix}"
        elif [ "$lane_kind" = u8 ]; then
            case "$architecture" in
                aarch64) selected_symbol="neon_${operation}" ;;
                x86_64) selected_symbol="u8_${operation}" ;;
            esac
        else
            selected_symbol="native_${operation}_i8x16"
        fi
        require_at_most "backends__native__${selected_symbol}${symbol_end}" 2 \
          "$caller" "two matching selected parts in ${lane_kind} ${operation}"
        require_at_most 'flyology_simd__backends__native__' 2 "$caller" \
          "only two matching selected operations in ${lane_kind} ${operation}"
        require_route_branches_at_most "$wide_saturation_branch" 2 "$caller" \
          "only two out-of-line branches in ${lane_kind} ${operation}"
    fi
    forbid_pattern 'flyology_simd__(wide__(native__)?|backends__scalar__)?(add_saturate|subtract_saturate)(__[0-9]+)?([+-]0x[[:xdigit:]]+)?([[:space:]]|$)|wide__byte_mechanism__' \
      "$caller" \
      "portable, dispatcher, Scalar, or byte-mechanism route in ${lane_kind} ${operation}"
done <scripts/probes/wide_saturating_arithmetic_codegen_cases.txt

require_native_route 'flyology_simd__backends__native__(add_saturate|subtract_saturate)__(3|4|5|6|7|8)$' 12 \
  "$temporary/wide-saturating-arithmetic-undefined.txt" "$temporary/wide-saturating-arithmetic-probe.txt" \
  'twelve selected non-byte Wide saturation operations'
if [ "$wide_backend" = avx2 ]; then
    require_count 'flyology_simd__wide__byte_avx2_leaf__(add_saturate|subtract_saturate)(__2)?$' 4 \
      "$temporary/wide-saturating-arithmetic-undefined.txt" \
      'four isolated AVX2 byte saturation operations'
else
    case "$architecture" in
        aarch64) u8_prefix=neon ;;
        x86_64) u8_prefix=u8 ;;
    esac
    require_native_route "flyology_simd__backends__native__${u8_prefix}_(add_saturate|subtract_saturate)$" 2 \
      "$temporary/wide-saturating-arithmetic-undefined.txt" "$temporary/wide-saturating-arithmetic-probe.txt" \
      'two selected U8 Wide saturation operations'
    require_native_route 'flyology_simd__backends__native__native_(add_saturate|subtract_saturate)_i8x16$' 2 \
      "$temporary/wide-saturating-arithmetic-undefined.txt" "$temporary/wide-saturating-arithmetic-probe.txt" \
      'two selected I8 Wide saturation operations'
fi
require_at_most 'flyology_simd__' 16 \
  "$temporary/wide-saturating-arithmetic-undefined.txt" \
  'only the 16 intended Wide saturation operations remain unresolved'
forbid_pattern 'flyology_simd__(wide__(native__)?|backends__scalar__)?(add_saturate|subtract_saturate)(__[0-9]+)?$|wide__byte_mechanism__' \
  "$temporary/wide-saturating-arithmetic-undefined.txt" \
  'portable, dispatcher, Scalar, or byte-mechanism route retained in Wide saturation probe'

wide_wrapping_case_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/wide_wrapping_arithmetic_codegen_cases.txt | wc -l | tr -d ' ')
wide_wrapping_unique_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/wide_wrapping_arithmetic_codegen_cases.txt | sort -u | wc -l | tr -d ' ')
if [ "$wide_wrapping_case_count" -ne 24 ] || \
   [ "$wide_wrapping_unique_count" -ne 24 ]; then
    echo 'Wide wrapping-arithmetic manifest must contain 24 unique operations' >&2
    exit 1
fi

case "$architecture" in
    aarch64) wide_wrapping_branch='(^|[[:space:]])(b|bl)[[:space:]]' ;;
    x86_64) wide_wrapping_branch='(^|[[:space:]])(callq?|jmpq?)[[:space:]]' ;;
esac

while read -r lane_kind operation wide_suffix half_suffix route; do
    [ -n "$lane_kind" ] || continue
    caller="$temporary/wide-wrapping-${lane_kind}-${operation}.txt"
    extract_symbol "wide_wrapping_arithmetic_codegen_probe__${lane_kind}_${operation}" \
      "$temporary/wide-wrapping-arithmetic-probe.txt" "$caller"
    symbol_end='([+-]0x[[:xdigit:]]+)?([[:space:]]|$)'
    if [ "$wide_backend" = avx2 ] && [ "$route" = byte ]; then
        leaf_suffix=
        [ "$lane_kind" = i8 ] && leaf_suffix='__2'
        require_count "wide__byte_avx2_leaf__${operation}${leaf_suffix}${symbol_end}" 1 \
          "$caller" "matching isolated AVX2 leaf in ${lane_kind} ${operation}"
        require_count 'wide__byte_avx2_leaf__' 1 "$caller" \
          "only one AVX2 byte leaf in ${lane_kind} ${operation}"
        require_route_branches_at_most "$wide_wrapping_branch" 1 "$caller" \
          "only one out-of-line branch in AVX2 ${lane_kind} ${operation}"
        require_at_most 'flyology_simd__backends__native__' 0 "$caller" \
          "no composed selected operation in AVX2 ${lane_kind} ${operation}"
    else
        if [ "$route" = parts ]; then
            selected_symbol="${operation}__${half_suffix}"
        elif [ "$lane_kind" = u8 ]; then
            case "$architecture" in
                aarch64) selected_symbol="neon_${operation}" ;;
                x86_64) selected_symbol="u8_${operation}" ;;
            esac
        else
            selected_symbol="native_${operation}_i8x16"
        fi
        require_at_most "backends__native__${selected_symbol}${symbol_end}" 2 \
          "$caller" "two matching selected parts in ${lane_kind} ${operation}"
        require_at_most 'flyology_simd__backends__native__' 2 "$caller" \
          "only two matching selected operations in ${lane_kind} ${operation}"
        require_route_branches_at_most "$wide_wrapping_branch" 2 "$caller" \
          "only two out-of-line branches in ${lane_kind} ${operation}"
    fi
    forbid_pattern 'flyology_simd__(wide__(native__)?|backends__scalar__)?(add_wrap|subtract_wrap|multiply_wrap)(__[0-9]+)?([+-]0x[[:xdigit:]]+)?([[:space:]]|$)|wide__byte_mechanism__' \
      "$caller" \
      "portable, dispatcher, Scalar, or byte-mechanism route in ${lane_kind} ${operation}"
done <scripts/probes/wide_wrapping_arithmetic_codegen_cases.txt

require_native_route 'flyology_simd__backends__native__(add_wrap|subtract_wrap|multiply_wrap)__(3|4|5|6|7|8)$' 18 \
  "$temporary/wide-wrapping-arithmetic-undefined.txt" "$temporary/wide-wrapping-arithmetic-probe.txt" \
  'eighteen selected non-byte Wide wrapping operations'
if [ "$wide_backend" = avx2 ]; then
    require_count 'flyology_simd__wide__byte_avx2_leaf__(add_wrap|subtract_wrap|multiply_wrap)(__2)?$' 6 \
      "$temporary/wide-wrapping-arithmetic-undefined.txt" \
      'six isolated AVX2 byte wrapping operations'
else
    case "$architecture" in
        aarch64) u8_prefix=neon ;;
        x86_64) u8_prefix=u8 ;;
    esac
    require_native_route "flyology_simd__backends__native__${u8_prefix}_(add_wrap|subtract_wrap|multiply_wrap)$" 3 \
      "$temporary/wide-wrapping-arithmetic-undefined.txt" "$temporary/wide-wrapping-arithmetic-probe.txt" \
      'three selected U8 Wide wrapping operations'
    require_native_route 'flyology_simd__backends__native__native_(add_wrap|subtract_wrap|multiply_wrap)_i8x16$' 3 \
      "$temporary/wide-wrapping-arithmetic-undefined.txt" "$temporary/wide-wrapping-arithmetic-probe.txt" \
      'three selected I8 Wide wrapping operations'
fi
require_at_most 'flyology_simd__' 24 \
  "$temporary/wide-wrapping-arithmetic-undefined.txt" \
  'only the 24 intended Wide wrapping operations remain unresolved'
forbid_pattern 'flyology_simd__(wide__(native__)?|backends__scalar__)?(add_wrap|subtract_wrap|multiply_wrap)(__[0-9]+)?$|wide__byte_mechanism__' \
  "$temporary/wide-wrapping-arithmetic-undefined.txt" \
  'portable, dispatcher, Scalar, or byte-mechanism route retained in Wide wrapping probe'

wide_bitwise_case_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/wide_bitwise_codegen_cases.txt | wc -l | tr -d ' ')
wide_bitwise_unique_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/wide_bitwise_codegen_cases.txt | sort -u | wc -l | tr -d ' ')
if [ "$wide_bitwise_case_count" -ne 32 ] || [ "$wide_bitwise_unique_count" -ne 32 ]; then
    echo 'Wide bitwise manifest must contain 32 unique operations' >&2
    exit 1
fi
case "$architecture" in
    aarch64) wide_bitwise_branch='(^|[[:space:]])(b|bl)[[:space:]]' ;;
    x86_64) wide_bitwise_branch='(^|[[:space:]])(callq?|jmpq?)[[:space:]]' ;;
esac
while read -r lane_kind operation half_suffix route arity; do
    [ -n "$lane_kind" ] || continue
    caller="$temporary/wide-bitwise-${lane_kind}-${operation}.txt"
    extract_symbol "wide_bitwise_codegen_probe__${lane_kind}_${operation}" \
      "$temporary/wide-bitwise-probe.txt" "$caller"
    symbol_end='([+-]0x[[:xdigit:]]+)?([[:space:]]|$)'
    if [ "$wide_backend" = avx2 ] && [ "$route" = byte ]; then
        leaf_suffix=
        [ "$lane_kind" = i8 ] && leaf_suffix='__2'
        require_count "wide__byte_avx2_leaf__${operation}${leaf_suffix}${symbol_end}" 1 \
          "$caller" "matching isolated AVX2 leaf in ${lane_kind} ${operation}"
        require_count 'wide__byte_avx2_leaf__' 1 "$caller" \
          "only one AVX2 byte leaf in ${lane_kind} ${operation}"
        require_route_branches_at_most "$wide_bitwise_branch" 1 "$caller" \
          "one out-of-line AVX2 branch in ${lane_kind} ${operation}"
        require_at_most 'flyology_simd__backends__native__' 0 "$caller" \
          "no composed selected operation in AVX2 ${lane_kind} ${operation}"
    elif [ "$lane_kind" = u8 ] && [ "$operation" = bitwise_and ]; then
        require_at_most 'flyology_simd__backends__native__' 0 "$caller" \
          'inline U8 conjunction has no selected call'
        require_route_branches_at_most "$wide_bitwise_branch" 0 "$caller" \
          'inline U8 conjunction has no out-of-line branch'
        case "$architecture" in
            aarch64) require_count 'and.*16b' 2 "$caller" 'two inline AArch64 U8 conjunctions' ;;
            x86_64) require_count 'pand' 2 "$caller" 'two inline SSE2 U8 conjunctions' ;;
        esac
    else
        if [ "$route" = parts ]; then
            selected_symbol="${operation}__${half_suffix}"
        elif [ "$lane_kind" = u8 ]; then
            case "$architecture" in
                aarch64) selected_symbol="neon_${operation}" ;;
                x86_64) selected_symbol="u8_${operation#bitwise_}" ;;
            esac
        else
            case "$operation" in
                bitwise_not) selected_symbol=native_not_i8x16 ;;
                *) selected_symbol="native_${operation}_i8x16" ;;
            esac
        fi
        require_at_most "backends__native__${selected_symbol}${symbol_end}" 2 "$caller" \
          "two matching selected parts in ${lane_kind} ${operation}"
        require_at_most 'flyology_simd__backends__native__' 2 "$caller" \
          "only two selected operations in ${lane_kind} ${operation}"
        require_route_branches_at_most "$wide_bitwise_branch" 2 "$caller" \
          "two out-of-line branches in ${lane_kind} ${operation}"
    fi
    forbid_pattern 'flyology_simd__(wide__(native__)?|backends__scalar__)?bitwise_(and|or|xor|not)(__[0-9]+)?([+-]0x[[:xdigit:]]+)?([[:space:]]|$)|wide__byte_mechanism__' \
      "$caller" "portable, dispatcher, Scalar, or byte-mechanism bitwise route"
done <scripts/probes/wide_bitwise_codegen_cases.txt

require_native_route 'flyology_simd__backends__native__bitwise_(and|or|xor|not)__(3|4|5|6|7|8)$' 24 \
  "$temporary/wide-bitwise-undefined.txt" "$temporary/wide-bitwise-probe.txt" 'twenty-four selected non-byte Wide bitwise operations'
if [ "$wide_backend" = avx2 ]; then
    require_count 'flyology_simd__wide__byte_avx2_leaf__bitwise_(and|or|xor|not)(__2)?$' 8 \
      "$temporary/wide-bitwise-undefined.txt" 'eight isolated AVX2 byte bitwise operations'
    expected_wide_bitwise_symbols=32
else
    require_native_route 'flyology_simd__backends__native__native_(bitwise_(and|or|xor)|not)_i8x16$' 4 \
      "$temporary/wide-bitwise-undefined.txt" "$temporary/wide-bitwise-probe.txt" 'four selected I8 Wide bitwise operations'
    case "$architecture" in aarch64) u8_prefix=neon_bitwise ;; x86_64) u8_prefix=u8 ;; esac
    require_native_route "flyology_simd__backends__native__${u8_prefix}_(or|xor|not)$" 3 \
      "$temporary/wide-bitwise-undefined.txt" "$temporary/wide-bitwise-probe.txt" 'three out-of-line U8 Wide bitwise operations'
    expected_wide_bitwise_symbols=31
fi
require_at_most 'flyology_simd__' "$expected_wide_bitwise_symbols" \
  "$temporary/wide-bitwise-undefined.txt" 'only intended Wide bitwise operations remain unresolved'
forbid_pattern 'flyology_simd__(wide__(native__)?|backends__scalar__)?bitwise_(and|or|xor|not)(__[0-9]+)?$|wide__byte_mechanism__' \
  "$temporary/wide-bitwise-undefined.txt" 'portable, dispatcher, Scalar, or byte-mechanism bitwise route retained'

wide_shift_case_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/wide_shift_codegen_cases.txt | wc -l | tr -d ' ')
wide_shift_unique_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/wide_shift_codegen_cases.txt | sort -u | wc -l | tr -d ' ')
if [ "$wide_shift_case_count" -ne 20 ] || [ "$wide_shift_unique_count" -ne 20 ]; then
    echo 'Wide shift manifest must contain 20 unique operations' >&2
    exit 1
fi
case "$architecture" in
    aarch64) wide_shift_branch='(^|[[:space:]])(b|bl)[[:space:]]' ;;
    x86_64) wide_shift_branch='(^|[[:space:]])(callq?|jmpq?)[[:space:]]' ;;
esac
while read -r lane_kind operation suffix; do
    [ -n "$lane_kind" ] || continue
    caller="$temporary/wide-shift-${lane_kind}-${operation}.txt"
    extract_symbol "wide_shift_codegen_probe__${lane_kind}_${operation}" \
      "$temporary/wide-shift-probe.txt" "$caller"
    symbol_suffix=
    [ "$suffix" != none ] && symbol_suffix="__${suffix}"
    symbol_end='([+-]0x[[:xdigit:]]+)?([[:space:]]|$)'
    require_at_most "backends__native__${operation}${symbol_suffix}${symbol_end}" 2 \
      "$caller" "two matching selected shifts in ${lane_kind} ${operation}"
    require_at_most 'flyology_simd__backends__native__' 2 "$caller" \
      "only two selected operations in ${lane_kind} ${operation}"
    require_route_branches_at_most "$wide_shift_branch" 2 "$caller" \
      "two out-of-line branches in ${lane_kind} ${operation}"
    forbid_pattern 'flyology_simd__(wide__(native__)?|backends__scalar__)?shift_(left_logical|right_logical|right_arithmetic)(__[0-9]+)?([+-]0x[[:xdigit:]]+)?([[:space:]]|$)' \
      "$caller" "portable, dispatcher, Scalar, or mismatched Wide shift route"
done <scripts/probes/wide_shift_codegen_cases.txt

require_native_route 'flyology_simd__backends__native__shift_(left_logical|right_logical|right_arithmetic)(__[0-9]+)?$' 20 \
  "$temporary/wide-shift-undefined.txt" "$temporary/wide-shift-probe.txt" \
  'twenty selected Wide shift operations remain unresolved'
require_at_most 'flyology_simd__' 20 "$temporary/wide-shift-undefined.txt" \
  'only the twenty intended Wide shift operations remain unresolved'
forbid_pattern 'flyology_simd__(wide__(native__)?|backends__scalar__)?shift_(left_logical|right_logical|right_arithmetic)(__[0-9]+)?$' \
  "$temporary/wide-shift-undefined.txt" \
  'portable, dispatcher, Scalar, or mismatched Wide shift route retained'

wide_minmax_case_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/wide_minmax_codegen_cases.txt | wc -l | tr -d ' ')
wide_minmax_unique_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/wide_minmax_codegen_cases.txt | sort -u | wc -l | tr -d ' ')
if [ "$wide_minmax_case_count" -ne 16 ] || [ "$wide_minmax_unique_count" -ne 16 ]; then
    echo 'Wide integer Min/Max manifest must contain 16 unique operations' >&2
    exit 1
fi
case "$architecture" in
    aarch64) wide_minmax_branch='(^|[[:space:]])(b|bl)[[:space:]]' ;;
    x86_64) wide_minmax_branch='(^|[[:space:]])(callq?|jmpq?)[[:space:]]' ;;
esac
while read -r lane_kind operation suffix route; do
    [ -n "$lane_kind" ] || continue
    caller="$temporary/wide-minmax-${lane_kind}-${operation}.txt"
    extract_symbol "wide_minmax_codegen_probe__${lane_kind}_${operation}" \
      "$temporary/wide-minmax-probe.txt" "$caller"
    symbol_end='([+-]0x[[:xdigit:]]+)?([[:space:]]|$)'
    if [ "$wide_backend" = avx2 ] && [ "$route" = byte ]; then
        leaf_suffix=
        [ "$lane_kind" = i8 ] && leaf_suffix='__2'
        require_count "wide__byte_avx2_leaf__${operation}${leaf_suffix}${symbol_end}" 1 \
          "$caller" "matching isolated AVX2 leaf in ${lane_kind} ${operation}"
        require_count 'wide__byte_avx2_leaf__' 1 "$caller" \
          "only one AVX2 byte leaf in ${lane_kind} ${operation}"
        require_route_branches_at_most "$wide_minmax_branch" 1 "$caller" \
          "one out-of-line AVX2 branch in ${lane_kind} ${operation}"
        require_at_most 'flyology_simd__backends__native__' 0 "$caller" \
          "no composed selected operation in AVX2 ${lane_kind} ${operation}"
    else
        if [ "$route" = parts ]; then
            selected_symbol="${operation}__${suffix}"
        elif [ "$lane_kind" = u8 ]; then
            case "$architecture" in
                aarch64) selected_symbol="neon_${operation}" ;;
                x86_64) selected_symbol="${operation}" ;;
            esac
        elif [ "$architecture" = x86_64 ]; then
            require_at_most 'backends__native__compare_greater_i8x16' 2 "$caller" \
              "two signed-byte comparisons in ${lane_kind} ${operation}"
            require_at_most 'backends__native__native_select_i8x16' 2 "$caller" \
              "two signed-byte selections in ${lane_kind} ${operation}"
            require_at_most 'backends__native__sign_8' 2 "$caller" \
              "two signed-byte comparison constants in ${lane_kind} ${operation}"
            require_at_most 'backends__native__weights_x86_8' 2 "$caller" \
              "two signed-byte selection constants in ${lane_kind} ${operation}"
            require_route_branches_at_most "$wide_minmax_branch" 4 "$caller" \
              "four exact inlined selected branches in ${lane_kind} ${operation}"
            selected_symbol=
        else
            selected_symbol="native_${operation}_i8x16"
        fi
        if [ -n "$selected_symbol" ]; then
            require_at_most "backends__native__${selected_symbol}${symbol_end}" 2 \
              "$caller" "two matching selected extrema in ${lane_kind} ${operation}"
            require_at_most 'flyology_simd__backends__native__' 2 "$caller" \
              "only two selected operations in ${lane_kind} ${operation}"
            require_route_branches_at_most "$wide_minmax_branch" 2 "$caller" \
              "two out-of-line branches in ${lane_kind} ${operation}"
        fi
    fi
    forbid_pattern 'flyology_simd__(wide__(native__)?|backends__scalar__)?(min|max)(__[0-9]+)?([+-]0x[[:xdigit:]]+)?([[:space:]]|$)|wide__byte_mechanism__' \
      "$caller" "portable, dispatcher, Scalar, or byte-mechanism extrema route"
done <scripts/probes/wide_minmax_codegen_cases.txt

require_native_route 'flyology_simd__backends__native__(min|max)__(3|4|5|6|7|8)$' 12 \
  "$temporary/wide-minmax-undefined.txt" "$temporary/wide-minmax-probe.txt" \
  'twelve selected non-byte Wide integer extrema operations'
if [ "$wide_backend" = avx2 ]; then
    require_count 'flyology_simd__wide__byte_avx2_leaf__(min|max)(__2)?$' 4 \
      "$temporary/wide-minmax-undefined.txt" \
      'four isolated AVX2 byte extrema operations'
else
    case "$architecture" in
        aarch64)
            require_native_route 'flyology_simd__backends__native__neon_(min|max)$' 2 \
              "$temporary/wide-minmax-undefined.txt" "$temporary/wide-minmax-probe.txt" 'two selected U8 Wide extrema operations'
            require_native_route 'flyology_simd__backends__native__native_(min|max)_i8x16$' 2 \
              "$temporary/wide-minmax-undefined.txt" "$temporary/wide-minmax-probe.txt" 'two selected I8 Wide extrema operations'
            expected_wide_minmax_symbols=16
            ;;
        x86_64)
            require_native_route 'flyology_simd__backends__native__(min|max)$' 2 \
              "$temporary/wide-minmax-undefined.txt" "$temporary/wide-minmax-probe.txt" 'two selected U8 Wide extrema operations'
            require_native_route 'flyology_simd__backends__native__(compare_greater_i8x16|native_select_i8x16)$' 2 \
              "$temporary/wide-minmax-undefined.txt" "$temporary/wide-minmax-probe.txt" 'two selected I8 extrema helpers'
            require_native_route 'flyology_simd__backends__native__(sign_8|weights_x86_8)$' 2 \
              "$temporary/wide-minmax-undefined.txt" "$temporary/wide-minmax-probe.txt" 'two selected I8 extrema constants'
            expected_wide_minmax_symbols=18
            ;;
    esac
fi
if [ "$wide_backend" = avx2 ]; then
    expected_wide_minmax_symbols=16
fi
require_at_most 'flyology_simd__' "$expected_wide_minmax_symbols" \
  "$temporary/wide-minmax-undefined.txt" \
  'only the intended Wide extrema routes remain unresolved'
forbid_pattern 'flyology_simd__(wide__(native__)?|backends__scalar__)?(min|max)(__[0-9]+)?$|wide__byte_mechanism__' \
  "$temporary/wide-minmax-undefined.txt" \
  'portable, dispatcher, Scalar, or byte-mechanism extrema route retained'

mask_core_case_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/mask_core_codegen_cases.txt | wc -l | tr -d ' ')
mask_core_unique_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/mask_core_codegen_cases.txt | sort -u | wc -l | tr -d ' ')
if [ "$mask_core_case_count" -ne 40 ] || [ "$mask_core_unique_count" -ne 40 ]; then
    echo 'fixed-width compact-mask manifest must contain 40 unique operations' >&2
    exit 1
fi

mask_core_operations='(mask_from_bit_mask|to_bit_mask|mask_and|mask_or|mask_xor|mask_not|test|any_true|all_true|none_true)'
case "$architecture" in
    aarch64) mask_core_branch='(^|[[:space:]])(b|bl)[[:space:]]' ;;
    x86_64) mask_core_branch='(^|[[:space:]])(callq?|jmpq?)[[:space:]]' ;;
esac
while read -r mask_kind operation suffix; do
    [ -n "$mask_kind" ] || continue
    caller="$temporary/mask-core-${mask_kind}-${operation}.txt"
    extract_symbol "mask_core_codegen_probe__${mask_kind}_${operation}" \
      "$temporary/mask-core-probe.txt" "$caller"
    symbol_suffix=
    [ "$suffix" != none ] && symbol_suffix="__${suffix}"
    symbol_end='([+-]0x[[:xdigit:]]+)?([[:space:]]|$)'

    if [ "$mask_kind" = m8 ] && \
       { [ "$operation" = mask_from_bit_mask ] || [ "$operation" = to_bit_mask ]; }; then
        require_at_most 'flyology_simd__' 0 "$caller" \
          "inline fixed-width ${operation} has no out-of-line operation"
        require_pattern '(^|[[:space:]])ret(q)?([[:space:]]|$)' "$caller" \
          "inline fixed-width ${operation} returns directly"
    else
        require_at_most "backends__native__${operation}${symbol_suffix}${symbol_end}" 1 \
          "$caller" "one matching fixed-width mask operation in ${mask_kind} ${operation}"
        require_at_most 'flyology_simd__backends__native__' 1 "$caller" \
          "only one selected mask operation in ${mask_kind} ${operation}"
        require_at_most "$mask_core_branch" 1 "$caller" \
          "one out-of-line branch in ${mask_kind} ${operation}"
    fi

    forbid_pattern "flyology_simd__${mask_core_operations}(__[0-9]+)?([+-]0x[[:xdigit:]]+)?([[:space:]]|$)|flyology_simd__backends__scalar__${mask_core_operations}(__[0-9]+)?([+-]0x[[:xdigit:]]+)?([[:space:]]|$)|flyology_simd__wide__(native__)?${mask_core_operations}(__[0-9]+)?([+-]0x[[:xdigit:]]+)?([[:space:]]|$)" \
      "$caller" "root, Scalar, or Wide compact-mask route"
done <scripts/probes/mask_core_codegen_cases.txt

require_native_route 'flyology_simd__backends__native__(mask_from_bit_mask|to_bit_mask)__(2|3|4)$' 6 \
  "$temporary/mask-core-undefined.txt" "$temporary/mask-core-probe.txt" \
  'six out-of-line fixed-width mask conversion operations remain unresolved'
require_native_route 'flyology_simd__backends__native__(mask_and|mask_or|mask_xor|mask_not|test|any_true|all_true|none_true)(__[234])?$' 32 \
  "$temporary/mask-core-undefined.txt" "$temporary/mask-core-probe.txt" \
  'thirty-two fixed-width mask algebra and query operations remain unresolved'
require_at_most 'flyology_simd__' 38 "$temporary/mask-core-undefined.txt" \
  'only the thirty-eight intended fixed-width mask operations remain unresolved'
forbid_pattern "flyology_simd__${mask_core_operations}(__[0-9]+)?$|flyology_simd__backends__scalar__${mask_core_operations}(__[0-9]+)?$|flyology_simd__wide__(native__)?${mask_core_operations}(__[0-9]+)?$" \
  "$temporary/mask-core-undefined.txt" \
  'root, Scalar, or Wide compact-mask route retained'

wide_mask_case_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/wide_mask_codegen_cases.txt | wc -l | tr -d ' ')
wide_mask_unique_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/wide_mask_codegen_cases.txt | sort -u | wc -l | tr -d ' ')
if [ "$wide_mask_case_count" -ne 52 ] || [ "$wide_mask_unique_count" -ne 52 ]; then
    echo 'Wide compact-mask manifest must contain 52 unique operations' >&2
    exit 1
fi

wide_mask_operations='(mask_from_bit_mask|to_bit_mask|mask_and|mask_or|mask_xor|mask_not|test|any_true|all_true|none_true|population_count|first_true|last_true)'
while read -r mask_kind operation suffix half_lanes; do
    [ -n "$mask_kind" ] || continue
    caller="$temporary/wide-mask-${mask_kind}-${operation}.txt"
    extract_symbol "wide_mask_codegen_probe__${mask_kind}_${operation}" \
      "$temporary/wide-mask-probe.txt" "$caller"
    symbol_suffix=
    [ "$suffix" != none ] && symbol_suffix="__${suffix}"
    symbol_end='([+-]0x[[:xdigit:]]+)?([[:space:]]|$)'

    if [ "$mask_kind" = m8 ] && \
       { [ "$operation" = mask_from_bit_mask ] || [ "$operation" = to_bit_mask ]; }; then
        require_at_most 'flyology_simd__' 0 "$caller" \
          "inline identity ${operation} has no out-of-line operation"
        require_pattern '(^|[[:space:]])ret(q)?([[:space:]]|$)' "$caller" \
          "inline identity ${operation} returns directly"
    elif [ "$operation" = test ]; then
        selected_count=$(grep -Eic \
          "backends__native__${operation}${symbol_suffix}${symbol_end}" "$caller" || true)
        if [ "$selected_count" -ne 1 ] && [ "$selected_count" -ne 2 ]; then
            echo "code-generation count mismatch: one merged or two branch Test calls in ${mask_kind} ($selected_count)" >&2
            exit 1
        fi
        require_count 'flyology_simd__backends__native__' "$selected_count" "$caller" \
          "only matching selected Test operations in ${mask_kind}"
    else
        require_at_most "backends__native__${operation}${symbol_suffix}${symbol_end}" 2 \
          "$caller" "two matching selected mask operations in ${mask_kind} ${operation}"
        require_at_most 'flyology_simd__backends__native__' 2 "$caller" \
          "only two selected mask operations in ${mask_kind} ${operation}"
    fi

    if [ "$operation" = test ]; then
        half_hex=$(printf '%x' "$half_lanes")
        case "$architecture" in
            aarch64)
                #  Apple objdump may print the immediate in decimal or hex.
                adjustment_pattern="sub.*#(0x${half_hex}|${half_lanes})([^[:xdigit:]]|$)"
                branch_pattern='(^|[[:space:]])b\.[a-z]+'
                ;;
            x86_64)
                adjustment_pattern="(sub.*\\\$(0x${half_hex}|${half_lanes})([^[:xdigit:]]|$)|lea[lq]?[[:space:]].*-(0x${half_hex}|${half_lanes})\\([^)]*\\),[[:space:]]*%[[:alnum:]]+)"
                branch_pattern='(^|[[:space:]])j(a|ae|b|be|c|e|g|ge|l|le|na|nae|nb|nbe|nc|ne|ng|nge|nl|nle|no|np|ns|nz|o|p|pe|po|s|z)[[:space:]]'
                ;;
        esac
        require_pattern "$adjustment_pattern" "$caller" \
          "high-half lane adjustment in ${mask_kind} Test"
        require_pattern "$branch_pattern" "$caller" \
          "private-half conditional selection in ${mask_kind} Test"
    fi

    forbid_pattern "flyology_simd__(wide__(native__)?|backends__scalar__)?${wide_mask_operations}(__[0-9]+)?([+-]0x[[:xdigit:]]+)?([[:space:]]|$)" \
      "$caller" "portable, dispatcher, Scalar, or mismatched compact-mask route"
done <scripts/probes/wide_mask_codegen_cases.txt

require_native_route 'flyology_simd__backends__native__(mask_from_bit_mask|to_bit_mask)__(2|3|4)$' 6 \
  "$temporary/wide-mask-undefined.txt" "$temporary/wide-mask-probe.txt" \
  'six out-of-line Wide mask bit-conversion operations remain unresolved'
require_native_route 'flyology_simd__backends__native__(mask_and|mask_or|mask_xor|mask_not|test|any_true|all_true|none_true|population_count|first_true|last_true)(__[234])?$' 44 \
  "$temporary/wide-mask-undefined.txt" "$temporary/wide-mask-probe.txt" \
  'forty-four selected Wide mask algebra and query operations remain unresolved'
require_at_most 'flyology_simd__' 50 "$temporary/wide-mask-undefined.txt" \
  'only the fifty intended out-of-line Wide mask operations remain unresolved'
forbid_pattern "flyology_simd__(wide__(native__)?|backends__scalar__)?${wide_mask_operations}(__[0-9]+)?$" \
  "$temporary/wide-mask-undefined.txt" \
  'portable, dispatcher, Scalar, or mismatched compact-mask route retained'

wide_reduction_case_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/wide_reduction_codegen_cases.txt | wc -l | tr -d ' ')
wide_reduction_unique_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/wide_reduction_codegen_cases.txt | sort -u | wc -l | tr -d ' ')
if [ "$wide_reduction_case_count" -ne 24 ] || \
   [ "$wide_reduction_unique_count" -ne 24 ]; then
    echo 'Wide reduction code-generation manifest must contain 24 unique operations' >&2
    exit 1
fi

while read -r lane_kind operation combine suffix; do
    [ -n "$lane_kind" ] || continue
    caller="$temporary/wide-reduction-${lane_kind}-${operation}.txt"
    extract_symbol "wide_reduction_codegen_probe__${lane_kind}_${operation}" \
      "$temporary/wide-reduction-probe.txt" "$caller"
    if [ "$suffix" = none ]; then
        operation_symbol="${operation}"
        combine_symbol="${combine}"
        extract_symbol_name='extract'
        splat_symbol='splat'
    else
        operation_symbol="${operation}__${suffix}"
        combine_symbol="${combine}__${suffix}"
        extract_symbol_name="extract__${suffix}"
        splat_symbol="splat__${suffix}"
    fi
    symbol_end='([+-]0x[[:xdigit:]]+)?([[:space:]]|$)'
    require_at_most "backends__native__${operation_symbol}${symbol_end}" 2 \
      "$caller" "two matching selected reductions in ${lane_kind} ${operation}"
    require_at_most "backends__native__${combine_symbol}${symbol_end}" 1 \
      "$caller" "one matching selected combine in ${lane_kind} ${operation}"
    require_at_most "backends__native__${extract_symbol_name}${symbol_end}" 1 \
      "$caller" "one matching selected extraction in ${lane_kind} ${operation}"
    if grep -Eiq "backends__native__${splat_symbol}${symbol_end}" "$caller"; then
        require_at_most "backends__native__${splat_symbol}${symbol_end}" 2 \
          "$caller" "two matching selected splats in ${lane_kind} ${operation}"
        selected_operation_count=6
    else
        #  The byte family is generated like the rest now, so it broadcasts the
        #  same way and needs no case of its own.
        case "$architecture:$lane_kind" in
            aarch64:*)
                require_at_least 'dup(\.[0-9]+[bhsd])?[[:space:]]' 2 "$caller" \
                  "two inlined splats in ${lane_kind} ${operation}"
                ;;
            x86_64:*)
                require_at_least 'pshufd|punpcklqdq|shufps|unpcklpd' 2 "$caller" \
                  "two inlined splat broadcasts in ${lane_kind} ${operation}"
                ;;
            *) echo "missing code-generation requirement: two matching selected splats in ${lane_kind} ${operation}" >&2; exit 1 ;;
        esac
        selected_operation_count=4
    fi
    require_at_most 'flyology_simd__backends__native__' \
      "$selected_operation_count" "$caller" \
      "only the intended selected operations in ${lane_kind} ${operation}"
    forbid_pattern 'flyology_simd__wide__(native__)?reduce_|flyology_simd__reduce_' \
      "$caller" "Wide dispatcher or portable scalar reduction in ${lane_kind} ${operation}"
done <scripts/probes/wide_reduction_codegen_cases.txt

forbid_pattern 'flyology_simd__wide__(native__)?reduce_|flyology_simd__reduce_' \
  "$temporary/wide-reduction-undefined.txt" \
  'Wide dispatcher or portable scalar reduction retained in caller probe'

integer_reduction_case_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/integer_reduction_codegen_cases.txt | wc -l | tr -d ' ')
integer_reduction_unique_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/integer_reduction_codegen_cases.txt | sort -u | wc -l | tr -d ' ')
if [ "$integer_reduction_case_count" -ne 24 ] || \
   [ "$integer_reduction_unique_count" -ne 24 ]; then
    echo '128-bit integer-reduction manifest must contain 24 unique operations' >&2
    exit 1
fi

while read -r lane_kind operation suffix bits lanes signedness; do
    [ -n "$lane_kind" ] || continue
    caller="$temporary/integer-reduction-${lane_kind}-${operation}.txt"
    extract_symbol "integer_reduction_codegen_probe__${lane_kind}_${operation}" \
      "$temporary/integer-reduction-probe.txt" "$caller"
    symbol_suffix=
    [ "$suffix" = none ] || symbol_suffix="__${suffix}"
    symbol_end='([+-]0x[[:xdigit:]]+)?([[:space:]]|$)'
    require_at_most "backends__native__${operation}${symbol_suffix}${symbol_end}" 1 \
      "$caller" "matching selected ${lane_kind} ${operation} caller"
    require_at_most 'flyology_simd__backends__native__' 1 "$caller" \
      "only one selected operation in ${lane_kind} ${operation} caller"
    require_at_most '(^|[[:space:]])(b|bl|callq?|jmpq?)[[:space:]]' 1 "$caller" \
      "only one out-of-line branch in ${lane_kind} ${operation} caller"
    forbid_pattern 'flyology_simd__(backends__scalar__)?reduce_|flyology_simd__wide__' \
      "$caller" "portable, Scalar, or Wide reduction in ${lane_kind} ${operation} caller"
done <scripts/probes/integer_reduction_codegen_cases.txt

require_native_route 'flyology_simd__backends__native__reduce_(add_wrap|min|max)(__[2-8])?$' 24 \
  "$temporary/integer-reduction-undefined.txt" "$temporary/integer-reduction-probe.txt" \
  'all 24 selected 128-bit integer-reduction overloads'
require_at_most 'flyology_simd__' 24 \
  "$temporary/integer-reduction-undefined.txt" \
  'only the 24 intended reductions remain unresolved from the caller probe'
forbid_pattern 'flyology_simd__(backends__scalar__)?reduce_|flyology_simd__wide__' \
  "$temporary/integer-reduction-undefined.txt" \
  'portable, Scalar, or Wide reduction retained in the 128-bit caller probe'

wrapping_arithmetic_case_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/wrapping_arithmetic_codegen_cases.txt | wc -l | tr -d ' ')
wrapping_arithmetic_unique_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/wrapping_arithmetic_codegen_cases.txt | sort -u | wc -l | tr -d ' ')
if [ "$wrapping_arithmetic_case_count" -ne 24 ] || \
   [ "$wrapping_arithmetic_unique_count" -ne 24 ]; then
    echo 'fixed-width wrapping-arithmetic manifest must contain 24 unique operations' >&2
    exit 1
fi
while read -r lane_kind operation suffix bits lanes; do
    [ -n "$lane_kind" ] || continue
    caller="$temporary/wrapping-arithmetic-${lane_kind}-${operation}.txt"
    extract_symbol "wrapping_arithmetic_codegen_probe__${lane_kind}_${operation}" \
      "$temporary/wrapping-arithmetic-probe.txt" "$caller"
    symbol_suffix=
    [ "$suffix" = none ] || symbol_suffix="__${suffix}"
    symbol_end='([+-]0x[[:xdigit:]]+)?([[:space:]]|$)'
    require_at_most "backends__native__${operation}${symbol_suffix}${symbol_end}" 1 \
      "$caller" "matching selected ${lane_kind} ${operation} caller"
    require_at_most 'flyology_simd__backends__native__' 1 "$caller" \
      "only one selected operation in ${lane_kind} ${operation} caller"
    require_at_most '(^|[[:space:]])(b|bl|callq?|jmpq?)[[:space:]]' 1 "$caller" \
      "only one out-of-line branch in ${lane_kind} ${operation} caller"
    forbid_pattern 'flyology_simd__(backends__scalar__)?(add_wrap|subtract_wrap|multiply_wrap)|flyology_simd__wide__' \
      "$caller" "portable, Scalar, or Wide arithmetic in ${lane_kind} ${operation} caller"
done <scripts/probes/wrapping_arithmetic_codegen_cases.txt
require_native_route 'flyology_simd__backends__native__(add_wrap|subtract_wrap|multiply_wrap)(__[2-8])?$' 24 \
  "$temporary/wrapping-arithmetic-undefined.txt" "$temporary/wrapping-arithmetic-probe.txt" \
  'all 24 selected fixed-width wrapping-arithmetic operations'
require_at_most 'flyology_simd__' 24 \
  "$temporary/wrapping-arithmetic-undefined.txt" \
  'only the 24 intended wrapping operations remain unresolved'
forbid_pattern 'flyology_simd__(backends__scalar__)?(add_wrap|subtract_wrap|multiply_wrap)|flyology_simd__wide__' \
  "$temporary/wrapping-arithmetic-undefined.txt" \
  'portable, Scalar, or Wide arithmetic retained in the caller probe'

bitwise_case_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/bitwise_codegen_cases.txt | wc -l | tr -d ' ')
bitwise_unique_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/bitwise_codegen_cases.txt | sort -u | wc -l | tr -d ' ')
if [ "$bitwise_case_count" -ne 32 ] || [ "$bitwise_unique_count" -ne 32 ]; then
    echo 'fixed-width bitwise manifest must contain 32 unique operations' >&2
    exit 1
fi
while read -r lane_kind operation suffix bits lanes arity; do
    caller="$temporary/bitwise-${lane_kind}-${operation}.txt"
    extract_symbol "bitwise_codegen_probe__${lane_kind}_${operation}" \
      "$temporary/bitwise-probe.txt" "$caller"
    symbol_suffix=
    [ "$suffix" = none ] || symbol_suffix="__${suffix}"
    symbol_end='([+-]0x[[:xdigit:]]+)?([[:space:]]|$)'
    if [ "$lane_kind" = u8 ] && [ "$operation" = bitwise_and ]; then
        require_at_most 'flyology_simd__backends__native__' 0 "$caller" \
          'inlined U8x16 Bitwise_And caller has no selected relocation'
        require_at_most '(^|[[:space:]])(b|bl|callq?|jmpq?)[[:space:]]' 0 "$caller" \
          'inlined U8x16 Bitwise_And caller has no out-of-line branch'
    else
        require_at_most "backends__native__${operation}${symbol_suffix}${symbol_end}" 1 \
          "$caller" "matching selected ${lane_kind} ${operation} caller"
        require_at_most 'flyology_simd__backends__native__' 1 "$caller" \
          "only one selected bitwise operation in ${lane_kind} ${operation} caller"
        require_at_most '(^|[[:space:]])(b|bl|callq?|jmpq?)[[:space:]]' 1 "$caller" \
          "only one out-of-line branch in ${lane_kind} ${operation} caller"
    fi
    forbid_pattern 'flyology_simd__(backends__scalar__)?bitwise_(and|or|xor|not)|flyology_simd__wide__' \
      "$caller" "portable, Scalar, or Wide bitwise route in ${lane_kind} ${operation} caller"
done <scripts/probes/bitwise_codegen_cases.txt
require_native_route 'flyology_simd__backends__native__bitwise_(and|or|xor|not)(__[2-8])?$' 31 \
  "$temporary/bitwise-undefined.txt" "$temporary/bitwise-probe.txt" '31 selected plus one inlined fixed-width bitwise operation'
require_at_most 'flyology_simd__' 31 "$temporary/bitwise-undefined.txt" \
  'only the 31 intended out-of-line bitwise operations remain unresolved'
forbid_pattern 'flyology_simd__(backends__scalar__)?bitwise_(and|or|xor|not)|flyology_simd__wide__' \
  "$temporary/bitwise-undefined.txt" \
  'portable, Scalar, or Wide bitwise route retained in the caller probe'

integer_minmax_case_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/integer_minmax_codegen_cases.txt | wc -l | tr -d ' ')
integer_minmax_unique_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/integer_minmax_codegen_cases.txt | sort -u | wc -l | tr -d ' ')
if [ "$integer_minmax_case_count" -ne 16 ] || \
   [ "$integer_minmax_unique_count" -ne 16 ]; then
    echo 'fixed-width integer Min/Max manifest must contain 16 unique operations' >&2
    exit 1
fi
while read -r lane_kind operation suffix bits lanes signedness; do
    caller="$temporary/integer-minmax-${lane_kind}-${operation}.txt"
    extract_symbol "integer_minmax_codegen_probe__${lane_kind}_${operation}" \
      "$temporary/integer-minmax-probe.txt" "$caller"
    symbol_suffix=
    [ "$suffix" = none ] || symbol_suffix="__${suffix}"
    symbol_end='([+-]0x[[:xdigit:]]+)?([[:space:]]|$)'
    require_at_most "backends__native__${operation}${symbol_suffix}${symbol_end}" 1 \
      "$caller" "matching selected ${lane_kind} ${operation} caller"
    require_at_most 'flyology_simd__backends__native__' 1 "$caller" \
      "only one selected integer Min/Max operation in ${lane_kind} ${operation} caller"
    require_at_most '(^|[[:space:]])(b|bl|callq?|jmpq?)[[:space:]]' 1 "$caller" \
      "only one out-of-line branch in ${lane_kind} ${operation} caller"
    forbid_pattern 'flyology_simd__(backends__scalar__)?(min|max)(__[0-9]+)?|flyology_simd__wide__' \
      "$caller" "portable, Scalar, Wide, or mismatched Min/Max route in ${lane_kind} ${operation} caller"
done <scripts/probes/integer_minmax_codegen_cases.txt
require_native_route 'flyology_simd__backends__native__(min|max)(__[2-8])?$' 16 \
  "$temporary/integer-minmax-undefined.txt" "$temporary/integer-minmax-probe.txt" \
  'all 16 selected fixed-width integer Min/Max operations'
require_at_most 'flyology_simd__' 16 "$temporary/integer-minmax-undefined.txt" \
  'only the 16 intended integer Min/Max operations remain unresolved'
forbid_pattern 'flyology_simd__(backends__scalar__)?(min|max)(__[0-9]+)?|flyology_simd__wide__' \
  "$temporary/integer-minmax-undefined.txt" \
  'portable, Scalar, Wide, or mismatched Min/Max route retained in the caller probe'

saturating_arithmetic_case_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/saturating_arithmetic_codegen_cases.txt | wc -l | tr -d ' ')
saturating_arithmetic_unique_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/saturating_arithmetic_codegen_cases.txt | sort -u | wc -l | tr -d ' ')
if [ "$saturating_arithmetic_case_count" -ne 16 ] || \
   [ "$saturating_arithmetic_unique_count" -ne 16 ]; then
    echo 'fixed-width saturating-arithmetic manifest must contain 16 unique operations' >&2
    exit 1
fi
while read -r lane_kind operation suffix bits lanes signedness; do
    caller="$temporary/saturating-arithmetic-${lane_kind}-${operation}.txt"
    extract_symbol "saturating_arithmetic_codegen_probe__${lane_kind}_${operation}" \
      "$temporary/saturating-arithmetic-probe.txt" "$caller"
    symbol_suffix=
    [ "$suffix" = none ] || symbol_suffix="__${suffix}"
    symbol_end='([+-]0x[[:xdigit:]]+)?([[:space:]]|$)'
    require_at_most "backends__native__${operation}${symbol_suffix}${symbol_end}" 1 \
      "$caller" "matching selected ${lane_kind} ${operation} caller"
    require_at_most 'flyology_simd__backends__native__' 1 "$caller" \
      "only one selected saturating operation in ${lane_kind} ${operation} caller"
    require_at_most '(^|[[:space:]])(b|bl|callq?|jmpq?)[[:space:]]' 1 "$caller" \
      "only one out-of-line branch in ${lane_kind} ${operation} caller"
    forbid_pattern 'flyology_simd__(backends__scalar__)?(add_saturate|subtract_saturate)(__[0-9]+)?|flyology_simd__wide__' \
      "$caller" \
      "portable, Scalar, Wide, or mismatched saturation route in ${lane_kind} ${operation} caller"
done <scripts/probes/saturating_arithmetic_codegen_cases.txt
require_native_route 'flyology_simd__backends__native__(add_saturate|subtract_saturate)(__[2-8])?$' 16 \
  "$temporary/saturating-arithmetic-undefined.txt" "$temporary/saturating-arithmetic-probe.txt" \
  'all 16 selected fixed-width saturating-arithmetic operations'
require_at_most 'flyology_simd__' 16 \
  "$temporary/saturating-arithmetic-undefined.txt" \
  'only the 16 intended saturating operations remain unresolved'
forbid_pattern 'flyology_simd__(backends__scalar__)?(add_saturate|subtract_saturate)(__[0-9]+)?|flyology_simd__wide__' \
  "$temporary/saturating-arithmetic-undefined.txt" \
  'portable, Scalar, Wide, or mismatched saturation route retained in the caller probe'

lane_arrangement_case_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/lane_arrangement_codegen_cases.txt | wc -l | tr -d ' ')
lane_arrangement_unique_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/lane_arrangement_codegen_cases.txt | sort -u | wc -l | tr -d ' ')
if [ "$lane_arrangement_case_count" -ne 50 ] || \
   [ "$lane_arrangement_unique_count" -ne 50 ]; then
    echo 'fixed-width lane-arrangement manifest must contain 50 unique operations' >&2
    exit 1
fi
while read -r lane_kind operation suffix bits lanes; do
    caller="$temporary/lane-arrangement-${lane_kind}-${operation}.txt"
    extract_symbol "lane_arrangement_codegen_probe__${lane_kind}_${operation}" \
      "$temporary/lane-arrangement-probe.txt" "$caller"
    symbol_suffix=
    [ "$suffix" = none ] || symbol_suffix="__${suffix}"
    symbol_end='([+-]0x[[:xdigit:]]+)?([[:space:]]|$)'
    require_at_most "backends__native__${operation}${symbol_suffix}${symbol_end}" 1 \
      "$caller" "matching selected ${lane_kind} ${operation} caller"
    require_at_most 'flyology_simd__backends__native__' 1 "$caller" \
      "only one selected arrangement in ${lane_kind} ${operation} caller"
    require_at_most '(^|[[:space:]])(b|bl|callq?|jmpq?)[[:space:]]' 1 "$caller" \
      "only one out-of-line branch in ${lane_kind} ${operation} caller"
    forbid_pattern 'flyology_simd__(backends__scalar__)?(reverse_lanes|interleave_(low|high)|deinterleave_(even|odd))|flyology_simd__wide__' \
      "$caller" "portable, Scalar, or Wide arrangement in ${lane_kind} ${operation} caller"
done <scripts/probes/lane_arrangement_codegen_cases.txt
require_native_route 'flyology_simd__backends__native__(reverse_lanes|interleave_(low|high)|deinterleave_(even|odd))(__([2-9]|10))?$' 50 \
  "$temporary/lane-arrangement-undefined.txt" "$temporary/lane-arrangement-probe.txt" \
  'all 50 selected fixed-width lane arrangements'
require_at_most 'flyology_simd__' 50 "$temporary/lane-arrangement-undefined.txt" \
  'only the 50 intended lane arrangements remain unresolved'
forbid_pattern 'flyology_simd__(backends__scalar__)?(reverse_lanes|interleave_(low|high)|deinterleave_(even|odd))|flyology_simd__wide__' \
  "$temporary/lane-arrangement-undefined.txt" \
  'portable, Scalar, or Wide arrangement retained in the caller probe'

float_binary_case_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/float_binary_codegen_cases.txt | wc -l | tr -d ' ')
float_binary_unique_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/float_binary_codegen_cases.txt | sort -u | wc -l | tr -d ' ')
if [ "$float_binary_case_count" -ne 12 ] || [ "$float_binary_unique_count" -ne 12 ]; then
    echo 'floating binary-operation manifest must contain 12 unique operations' >&2
    exit 1
fi
while read -r lane_kind operation suffix shape x86_shape; do
    caller="$temporary/float-binary-${lane_kind}-${operation}.txt"
    extract_symbol "float_binary_codegen_probe__${lane_kind}_${operation}" \
      "$temporary/float-binary-probe.txt" "$caller"
    symbol_suffix=
    [ "$suffix" = none ] || symbol_suffix="__${suffix}"
    symbol_end='([+-]0x[[:xdigit:]]+)?([[:space:]]|$)'
    require_at_most "backends__native__${operation}${symbol_suffix}${symbol_end}" 1 \
      "$caller" "matching selected ${lane_kind} ${operation} caller"
    require_at_most 'flyology_simd__backends__native__' 1 "$caller" \
      "only one selected operation in ${lane_kind} ${operation} caller"
    require_at_most 'flyology_simd__' 1 "$caller" \
      "only the matching selected operation remains in ${lane_kind} ${operation} caller"
    require_at_most '(^|[[:space:]])(b|bl|callq?|jmpq?)[[:space:]]' 1 "$caller" \
      "only one out-of-line branch in ${lane_kind} ${operation} caller"
    forbid_pattern 'flyology_simd__(backends__scalar__)?(add|subtract|multiply|divide|min_number|max_number)|flyology_simd__wide__' \
      "$caller" "portable, Scalar, or Wide floating operation in ${lane_kind} ${operation} caller"
done <scripts/probes/float_binary_codegen_cases.txt
require_native_route 'flyology_simd__backends__native__(add|subtract|multiply|divide|min_number|max_number)(__2)?$' 12 \
  "$temporary/float-binary-undefined.txt" "$temporary/float-binary-probe.txt" 'all 12 selected floating binary operations'
require_at_most 'flyology_simd__' 12 "$temporary/float-binary-undefined.txt" \
  'only the 12 intended floating operations remain unresolved from the caller probe'

complete_memory_case_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/complete_memory_codegen_cases.txt | wc -l | tr -d ' ')
complete_memory_unique_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/complete_memory_codegen_cases.txt | sort -u | wc -l | tr -d ' ')
if [ "$complete_memory_case_count" -ne 60 ] || \
   [ "$complete_memory_unique_count" -ne 60 ]; then
    echo 'complete-memory manifest must contain 60 unique operations' >&2
    exit 1
fi
while read -r lane_kind operation suffix; do
    caller="$temporary/complete-memory-${lane_kind}-${operation}.txt"
    extract_symbol "complete_memory_codegen_probe__${lane_kind}_${operation}" \
      "$temporary/complete-memory-probe.txt" "$caller"
    symbol_suffix=
    [ "$suffix" = none ] || symbol_suffix="__${suffix}"
    symbol_end='([+-]0x[[:xdigit:]]+)?([[:space:]]|$)'
    if [ "$architecture" = aarch64 ] && \
       [ "$lane_kind" = u8 ] && [ "$operation" = load_unaligned ]; then
        require_at_most 'flyology_simd__backends__native__' 0 "$caller" \
          'inlined selected U8 Load_Unaligned caller'
        require_count '(^|[[:space:]])ldr[[:space:]]+q[0-9]+,[[:space:]]*\[' 1 "$caller" \
          'inlined U8 Load_Unaligned target load'
        require_count '(^|[[:space:]])str[[:space:]]+q[0-9]+,[[:space:]]*\[' 0 "$caller" \
          'no inlined U8 Load_Unaligned result store'
    elif [ "$architecture" = x86_64 ] && \
         [ "$lane_kind" = u8 ] && [ "$operation" = load_unaligned ]; then
        require_at_most 'flyology_simd__backends__native__' 0 "$caller" \
          'inlined selected U8 Load_Unaligned caller'
        #  The load lands straight in a register, so there is one movdqu from
        #  memory and no copy back out through a result buffer.
        require_at_least '(^|[[:space:]])movdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%xmm[0-9]' 1 "$caller" \
          'inlined U8 Load_Unaligned array-to-register transfer'
        require_count '(^|[[:space:]])movdqu[[:space:]]+%xmm[0-9]+,[[:space:]]*[^,]*\([^)]*\)' 0 "$caller" \
          'no inlined U8 Load_Unaligned result store'
    else
        require_at_most "backends__native__${operation}${symbol_suffix}${symbol_end}" 1 \
          "$caller" "matching selected ${lane_kind} ${operation} caller"
        require_at_most 'flyology_simd__backends__native__' 1 "$caller" \
          "only one selected memory operation in ${lane_kind} ${operation} caller"
        require_at_most 'flyology_simd__' 1 "$caller" \
          "only the matching selected memory operation remains in ${lane_kind} ${operation} caller"
        require_at_most '(^|[[:space:]])(b|bl|callq?|jmpq?)[[:space:]]' 1 "$caller" \
          "only one out-of-line branch in ${lane_kind} ${operation} caller"
    fi
    forbid_pattern 'flyology_simd__(backends__scalar__)?(load|store)(_unaligned|_aligned)?|flyology_simd__wide__' \
      "$caller" "portable, Scalar, or Wide memory call in ${lane_kind} ${operation} caller"
done <scripts/probes/complete_memory_codegen_cases.txt
require_native_route 'flyology_simd__backends__native__(load|store)(_unaligned|_aligned)?(__([2-9]|10))?$' 59 \
  "$temporary/complete-memory-undefined.txt" "$temporary/complete-memory-probe.txt" \
  'the 59 out-of-line selected complete-memory operations'
require_at_most 'flyology_simd__' 59 "$temporary/complete-memory-undefined.txt" \
  'only the intended complete-memory operations remain unresolved'

comparison_case_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/comparison_codegen_cases.txt | wc -l | tr -d ' ')
comparison_unique_count=$(sed '/^[[:space:]]*$/d' \
  scripts/probes/comparison_codegen_cases.txt | sort -u | wc -l | tr -d ' ')
if [ "$comparison_case_count" -ne 62 ] || \
   [ "$comparison_unique_count" -ne 62 ]; then
    echo 'fixed-width comparison manifest must contain 62 unique operations' >&2
    exit 1
fi
require_count 'Left => Right, Right => Left' 20 \
  "src/backends/${architecture}/flyology_simd-backends-native.adb" \
  "the ten less-than and ten less-equal reversed-operand definitions on ${architecture}"
while read -r lane_kind operation suffix; do
    [ -n "$lane_kind" ] || continue
    caller="$temporary/comparison-${lane_kind}-${operation}.txt"
    extract_symbol "comparison_codegen_probe__${lane_kind}_${operation}" \
      "$temporary/comparison-probe.txt" "$caller"
    require_count "comparison_codegen_probe__selected_${lane_kind}_${operation}" 1 \
      "$caller" "matching isolated ${lane_kind} ${operation} leaf"
    require_at_most '(^|[[:space:]])(b|bl|callq?|jmpq?)[[:space:]]' 1 "$caller" \
      "only one out-of-line branch in ${lane_kind} ${operation} caller"
    forbid_pattern 'flyology_simd__(backends__scalar__)?(equal|less_than|less_equal|greater_than|greater_equal|unordered|select_value)|flyology_simd__wide__' \
      "$caller" "portable, Scalar, or Wide comparison in ${lane_kind} ${operation} caller"
done <scripts/probes/comparison_codegen_cases.txt
require_native_route 'flyology_simd__backends__native__(equal|less_than|less_equal|greater_than|greater_equal|select_value)(__([2-9]|10))?$|flyology_simd__backends__native__unordered(__2)?$' 61 \
  "$temporary/comparison-undefined.txt" "$temporary/comparison-probe.txt" \
  'the 61 out-of-line selected comparison and selection overloads'
#  The U8x16 comparison leaf holds its compact-mask weight table in a vector
#  constant that the inliner materialises locally, so no architecture leaves an
#  external reference to the shared table behind.
require_native_route 'flyology_simd__backends__native__weights_8x16$' 0 \
  "$temporary/comparison-undefined.txt" "$temporary/comparison-probe.txt" \
  'no external U8 compact-mask weight table reference'
expected_comparison_symbols=61
require_at_most 'flyology_simd__' "$expected_comparison_symbols" \
  "$temporary/comparison-undefined.txt" \
  'only the intended fixed-width comparison routes remain unresolved'

while read -r lane_kind operation suffix; do
    [ -n "$lane_kind" ] || continue
    leaf="$temporary/comparison-leaf-${lane_kind}-${operation}.txt"
    extract_symbol "comparison_codegen_probe__selected_${lane_kind}_${operation}" \
      "$temporary/comparison-probe.txt" "$leaf"
    symbol_suffix=
    [ "$suffix" = none ] || symbol_suffix="__${suffix}"
    symbol_end='([+-]0x[[:xdigit:]]+)?([[:space:]]|$)'
    if grep -Eiq "backends__native__${operation}${symbol_suffix}${symbol_end}" "$leaf"; then
        extract_symbol "flyology_simd__backends__native__${operation}${symbol_suffix}" \
          "$temporary/native.txt" "$leaf"
    fi
    case "$lane_kind" in
        u8|i8) lane_shape=16b; x86_compare=pcmpgtb; x86_equal=pcmpeqb; compact_pattern='pmovmskb' ;;
        u16|i16) lane_shape=8h; x86_compare=pcmpgtw; x86_equal=pcmpeqw; compact_pattern='pmovmskb' ;;
        u32|i32) lane_shape=4s; x86_compare=pcmpgtd; x86_equal=pcmpeqd; compact_pattern='pmovmskb' ;;
        u64|i64) lane_shape=2d; x86_compare=pcmpgtd; x86_equal=pcmpeqd; compact_pattern='pmovmskb' ;;
        f32) lane_shape=4s; x86_equal=pcmpeqd; compact_pattern='pmovmskb' ;;
        f64) lane_shape=2d; x86_equal=pcmpeqd; compact_pattern='pmovmskb' ;;
    esac
    case "$architecture:$lane_kind:$operation" in
        aarch64:*:select_value)
            require_leaf_instruction "cmtst.*${lane_shape}" 1 "$leaf" "NEON ${lane_shape} mask expansion in ${lane_kind} selection"
            require_leaf_instruction 'bsl.*16b' 1 "$leaf" "NEON 128-bit selection in ${lane_kind} selection"
            ;;
        aarch64:f32:unordered|aarch64:f64:unordered)
            require_leaf_instruction "fcm(e|g)[a-z]*.*${lane_shape}" 2 "$leaf" "two NEON ${lane_shape} self comparisons in ${lane_kind} unordered"
            require_pattern '(^|[[:space:]])and' "$leaf" "ordered-mask conjunction in ${lane_kind} unordered"
            require_leaf_instruction '(^|[[:space:]])mvn' 1 "$leaf" "ordered-mask inversion in ${lane_kind} unordered"
            ;;
        aarch64:f32:equal|aarch64:f64:equal) require_leaf_instruction "fcmeq.*${lane_shape}" 1 "$leaf" "NEON floating equality in ${lane_kind}" ;;
        aarch64:f32:less_than|aarch64:f64:less_than|aarch64:f32:greater_than|aarch64:f64:greater_than) require_leaf_instruction "fcmgt.*${lane_shape}" 1 "$leaf" "NEON floating strict comparison in ${lane_kind} ${operation}" ;;
        aarch64:f32:less_equal|aarch64:f64:less_equal|aarch64:f32:greater_equal|aarch64:f64:greater_equal) require_leaf_instruction "fcmge.*${lane_shape}" 1 "$leaf" "NEON floating inclusive comparison in ${lane_kind} ${operation}" ;;
        aarch64:*:equal) require_leaf_instruction "cmeq.*${lane_shape}" 1 "$leaf" "NEON ${lane_shape} integer equality in ${lane_kind}" ;;
        aarch64:u*:less_than|aarch64:u*:greater_than) require_leaf_instruction "cmhi.*${lane_shape}" 1 "$leaf" "NEON unsigned ${lane_shape} strict comparison in ${lane_kind} ${operation}" ;;
        aarch64:u*:less_equal|aarch64:u*:greater_equal) require_leaf_instruction "cmhs.*${lane_shape}" 1 "$leaf" "NEON unsigned ${lane_shape} inclusive comparison in ${lane_kind} ${operation}" ;;
        aarch64:i*:less_than|aarch64:i*:greater_than) require_leaf_instruction "cmgt.*${lane_shape}" 1 "$leaf" "NEON signed ${lane_shape} strict comparison in ${lane_kind} ${operation}" ;;
        aarch64:i*:less_equal|aarch64:i*:greater_equal) require_leaf_instruction "cmge.*${lane_shape}" 1 "$leaf" "NEON signed ${lane_shape} inclusive comparison in ${lane_kind} ${operation}" ;;
        x86_64:*:select_value)
            require_pattern "$x86_equal" "$leaf" "SSE2 lane-width mask expansion in ${lane_kind} selection"
            require_pattern '(^|[[:space:]])pand' "$leaf" "SSE2 true-lane selection in ${lane_kind} selection"
            require_leaf_instruction '(^|[[:space:]])pandn' 1 "$leaf" "SSE2 false-lane selection in ${lane_kind} selection"
            require_leaf_instruction '(^|[[:space:]])por' 1 "$leaf" "SSE2 selected-lane merge in ${lane_kind} selection"
            ;;
        x86_64:f32:unordered) require_leaf_instruction 'cmpunordps' 1 "$leaf" 'SSE2 F32 unordered comparison' ;;
        x86_64:f64:unordered) require_leaf_instruction 'cmpunordpd' 1 "$leaf" 'SSE2 F64 unordered comparison' ;;
        x86_64:f32:equal) require_leaf_instruction 'cmpeqps' 1 "$leaf" 'SSE2 F32 equality' ;;
        x86_64:f64:equal) require_leaf_instruction 'cmpeqpd' 1 "$leaf" 'SSE2 F64 equality' ;;
        x86_64:f32:less_than|x86_64:f32:greater_than) require_leaf_instruction 'cmpltps' 1 "$leaf" "SSE2 F32 strict comparison in ${operation}" ;;
        x86_64:f64:less_than|x86_64:f64:greater_than) require_leaf_instruction 'cmpltpd' 1 "$leaf" "SSE2 F64 strict comparison in ${operation}" ;;
        x86_64:f32:less_equal|x86_64:f32:greater_equal) require_leaf_instruction 'cmpleps' 1 "$leaf" "SSE2 F32 inclusive comparison in ${operation}" ;;
        x86_64:f64:less_equal|x86_64:f64:greater_equal) require_leaf_instruction 'cmplepd' 1 "$leaf" "SSE2 F64 inclusive comparison in ${operation}" ;;
        x86_64:*:equal)
            require_leaf_instruction "$x86_equal" 1 "$leaf" "SSE2 lane-width integer equality in ${lane_kind}"
            require_leaf_instruction "$compact_pattern" 1 "$leaf" "SSE2 compact-mask extraction in ${lane_kind} equality"
            ;;
        x86_64:u*:less_than|x86_64:u*:less_equal|x86_64:u*:greater_than|x86_64:u*:greater_equal)
            require_pattern 'pxor' "$leaf" "unsigned sign-bit bias in ${lane_kind} ${operation}"
            require_pattern "$x86_compare" "$leaf" "SSE2 unsigned ordered comparison in ${lane_kind} ${operation}"
            ;;
        x86_64:i*:less_than|x86_64:i*:less_equal|x86_64:i*:greater_than|x86_64:i*:greater_equal)
            require_pattern "$x86_compare" "$leaf" "SSE2 signed ordered comparison in ${lane_kind} ${operation}"
            ;;
    esac
    case "$architecture:$operation" in
        x86_64:*less_equal|x86_64:*greater_equal)
            case "$lane_kind" in
                u8|i8|u16|i16|u32|i32)
                    require_leaf_instruction "$x86_equal" 1 "$leaf" "SSE2 equality component in ${lane_kind} ${operation}"
                    require_leaf_instruction "$compact_pattern" 2 "$leaf" "SSE2 strict and equality mask extraction in ${lane_kind} ${operation}"
                    case "$lane_kind" in
                        u8|i8) inclusive_or_count=1 ;;
                        u16|i16) inclusive_or_count=7 ;;
                        u32|i32) inclusive_or_count=5 ;;
                    esac
                    require_count '(^|[[:space:]])orl?' "$inclusive_or_count" "$leaf" \
                      "compact-mask construction and strict/equality merge in ${lane_kind} ${operation}"
                    ;;
            esac
            ;;
    esac
    case "$architecture:$operation" in
        x86_64:equal|x86_64:less_than|x86_64:less_equal|x86_64:greater_than|x86_64:greater_equal)
            require_pattern "$compact_pattern" "$leaf" "lane-width compact-mask extraction in ${lane_kind} ${operation}"
            ;;
    esac
    case "$architecture:$lane_kind:$operation" in
        x86_64:u8:less_than|x86_64:u8:less_equal|x86_64:u8:greater_than|x86_64:u8:greater_equal|x86_64:u16:less_than|x86_64:u16:less_equal|x86_64:u16:greater_than|x86_64:u16:greater_equal|x86_64:u32:less_than|x86_64:u32:less_equal|x86_64:u32:greater_than|x86_64:u32:greater_equal)
            require_leaf_instruction '(^|[[:space:]])pxor' 2 "$leaf" "two unsigned sign-bit transforms in ${lane_kind} ${operation}"
            ;;
        x86_64:u64:less_than|x86_64:u64:less_equal|x86_64:u64:greater_than|x86_64:u64:greater_equal|x86_64:i64:less_than|x86_64:i64:less_equal|x86_64:i64:greater_than|x86_64:i64:greater_equal)
            require_leaf_instruction 'pcmpgtd' 2 "$leaf" "high/low dword comparisons in ${lane_kind} ${operation}"
            require_pattern 'pcmpeqd' "$leaf" "high-dword equality gate in ${lane_kind} ${operation}"
            require_pattern 'pshufd' "$leaf" "dword-to-lane replication in ${lane_kind} ${operation}"
            require_pattern '(^|[[:space:]])pand' "$leaf" "equality-gated low comparison in ${lane_kind} ${operation}"
            require_pattern '(^|[[:space:]])por' "$leaf" "lexicographic comparison merge in ${lane_kind} ${operation}"
            if [ "$lane_kind" = u64 ]; then
                require_leaf_instruction '(^|[[:space:]])pxor' 4 "$leaf" "unsigned high/low dword sign transforms in ${lane_kind} ${operation}"
            else
                require_leaf_instruction '(^|[[:space:]])pxor' 2 "$leaf" "signed low-dword sign transforms in ${lane_kind} ${operation}"
            fi
            ;;
        x86_64:u64:equal|x86_64:i64:equal)
            require_leaf_instruction 'pcmpeqd' 1 "$leaf" "dword equality in ${lane_kind} equality"
            require_leaf_instruction 'pshufd' 2 "$leaf" "adjacent-dword equality replication in ${lane_kind} equality"
            require_leaf_instruction '(^|[[:space:]])pand' 1 "$leaf" "adjacent-dword equality conjunction in ${lane_kind} equality"
            ;;
    esac
    case "$architecture:$lane_kind:$operation" in
        aarch64:u8:equal|aarch64:u8:less_than|aarch64:u8:less_equal|aarch64:u8:greater_than|aarch64:u8:greater_equal|aarch64:i8:equal|aarch64:i8:less_than|aarch64:i8:less_equal|aarch64:i8:greater_than|aarch64:i8:greater_equal)
            require_leaf_instruction 'and.*16b' 1 "$leaf" "byte comparison weight mask in ${lane_kind} ${operation}"
            require_leaf_instruction 'ext.*16b' 1 "$leaf" "byte comparison half advance in ${lane_kind} ${operation}"
            require_leaf_instruction 'uaddlv.*8b' 2 "$leaf" "byte comparison half sums in ${lane_kind} ${operation}"
            require_leaf_instruction 'umov.*h' 2 "$leaf" "byte compact-mask transfers in ${lane_kind} ${operation}"
            ;;
        aarch64:u16:equal|aarch64:u16:less_than|aarch64:u16:less_equal|aarch64:u16:greater_than|aarch64:u16:greater_equal|aarch64:i16:equal|aarch64:i16:less_than|aarch64:i16:less_equal|aarch64:i16:greater_than|aarch64:i16:greater_equal)
            require_leaf_instruction 'ushr.*8h' 1 "$leaf" "16-bit comparison normalization in ${lane_kind} ${operation}"
            require_leaf_instruction 'mul.*8h' 1 "$leaf" "16-bit compact-mask weighting in ${lane_kind} ${operation}"
            require_leaf_instruction 'addv.*8h' 1 "$leaf" "16-bit compact-mask reduction in ${lane_kind} ${operation}"
            ;;
        aarch64:u32:equal|aarch64:u32:less_than|aarch64:u32:less_equal|aarch64:u32:greater_than|aarch64:u32:greater_equal|aarch64:i32:equal|aarch64:i32:less_than|aarch64:i32:less_equal|aarch64:i32:greater_than|aarch64:i32:greater_equal|aarch64:f32:equal|aarch64:f32:less_than|aarch64:f32:less_equal|aarch64:f32:greater_than|aarch64:f32:greater_equal)
            require_leaf_instruction 'ushr.*4s' 1 "$leaf" "32-bit comparison normalization in ${lane_kind} ${operation}"
            require_leaf_instruction 'mul.*4s' 1 "$leaf" "32-bit compact-mask weighting in ${lane_kind} ${operation}"
            require_leaf_instruction 'addv.*4s' 1 "$leaf" "32-bit compact-mask reduction in ${lane_kind} ${operation}"
            ;;
        aarch64:u64:equal|aarch64:u64:less_than|aarch64:u64:less_equal|aarch64:u64:greater_than|aarch64:u64:greater_equal|aarch64:i64:equal|aarch64:i64:less_than|aarch64:i64:less_equal|aarch64:i64:greater_than|aarch64:i64:greater_equal|aarch64:f64:equal|aarch64:f64:less_than|aarch64:f64:less_equal|aarch64:f64:greater_than|aarch64:f64:greater_equal)
            require_leaf_instruction 'ushr.*2d' 1 "$leaf" "64-bit comparison normalization in ${lane_kind} ${operation}"
            require_leaf_instruction '(^|[[:space:]])and' 1 "$leaf" "64-bit compact-mask merge in ${lane_kind} ${operation}"
            ;;
    esac
    forbid_pattern '(^|[[:space:]])(b|bl|callq?|jmpq?)[[:space:]]' "$leaf" \
      "branch or out-of-line helper in isolated ${lane_kind} ${operation} leaf"
done <scripts/probes/comparison_codegen_cases.txt

case "$architecture" in
    aarch64)
        while read -r lane_kind operation suffix bits lanes; do
            symbol_suffix=
            [ "$suffix" = none ] || symbol_suffix="__${suffix}"
            leaf="$temporary/wrapping-arithmetic-leaf-${lane_kind}-${operation}.txt"
            extract_leaf_or_probe "flyology_simd__backends__native__${operation}${symbol_suffix}" \
              "$temporary/native.txt" \
              "wrapping_arithmetic_codegen_probe__${lane_kind}_${operation}" \
              "$temporary/wrapping-arithmetic-probe.txt" "$leaf"
            require_vector_operand_transfers "$leaf" "$lane_kind" "$operation" 2
            case "$bits" in
                8) shape=16b ;;
                16) shape=8h ;;
                32) shape=4s ;;
                64) shape=2d ;;
            esac
            case "$operation" in
                add_wrap) require_leaf_instruction "(^|[[:space:]])(add\.${shape}[[:space:]]|add[[:space:]].*\.${shape}([^[:alnum:]]|$))" 1 "$leaf" "exact NEON ${shape} ${operation} leaf" ;;
                subtract_wrap) require_leaf_instruction "(^|[[:space:]])(sub\.${shape}[[:space:]]|sub[[:space:]].*\.${shape}([^[:alnum:]]|$))" 1 "$leaf" "exact NEON ${shape} ${operation} leaf" ;;
                multiply_wrap)
                    if [ "$bits" -lt 64 ]; then
                        require_leaf_instruction "(^|[[:space:]])(mul\.${shape}[[:space:]]|mul[[:space:]].*\.${shape}([^[:alnum:]]|$))" 1 "$leaf" "exact NEON ${shape} ${operation} leaf"
                    else
                        require_leaf_instruction '(^|[[:space:]])uzp1(\.4s)?[[:space:]]' 2 "$leaf" "two low-word deinterleaves in ${lane_kind} multiplication"
                        require_leaf_instruction '(^|[[:space:]])uzp2(\.4s)?[[:space:]]' 2 "$leaf" "two high-word deinterleaves in ${lane_kind} multiplication"
                        require_leaf_instruction '(^|[[:space:]])umull(\.2d)?[[:space:]]' 1 "$leaf" "one low-word full product in ${lane_kind} multiplication"
                        require_leaf_instruction '(^|[[:space:]])mul(\.2s)?[[:space:]]' 1 "$leaf" "one first cross product in ${lane_kind} multiplication"
                        require_leaf_instruction '(^|[[:space:]])mla(\.2s)?[[:space:]]' 1 "$leaf" "one second cross product in ${lane_kind} multiplication"
                        require_leaf_instruction '(^|[[:space:]])shll(\.2d)?[[:space:]].*#(32|0x20)([^[:xdigit:]]|$)' 1 "$leaf" "32-bit cross-product shift in ${lane_kind} multiplication"
                        require_leaf_instruction '(^|[[:space:]])add(\.2d)?[[:space:]]+v[0-9]+' 1 "$leaf" "one modulo-64 product combination in ${lane_kind} multiplication"
                    fi
                    ;;
            esac
            forbid_pattern '(^|[[:space:]])(b(\.[a-z]+)?|bl)[[:space:]]' "$leaf" \
              "branch or out-of-line helper in ${lane_kind} ${operation} leaf"
        done <scripts/probes/wrapping_arithmetic_codegen_cases.txt
        while read -r lane_kind operation suffix bits lanes arity; do
            symbol_suffix=
            [ "$suffix" = none ] || symbol_suffix="__${suffix}"
            leaf="$temporary/bitwise-leaf-${lane_kind}-${operation}.txt"
            if [ "$lane_kind" = u8 ] && [ "$operation" = bitwise_and ]; then
                extract_symbol 'bitwise_codegen_probe__u8_bitwise_and' \
                  "$temporary/bitwise-probe.txt" "$leaf"
            else
                extract_leaf_or_probe "flyology_simd__backends__native__${operation}${symbol_suffix}" \
                  "$temporary/native.txt" \
                  "bitwise_codegen_probe__${lane_kind}_${operation}" \
                  "$temporary/bitwise-probe.txt" "$leaf"
            fi
            require_vector_operand_transfers "$leaf" "$lane_kind" "$operation" "$arity"
            case "$operation" in
                bitwise_and) instruction=and ;;
                bitwise_or) instruction=orr ;;
                bitwise_xor) instruction=eor ;;
                bitwise_not) instruction=mvn ;;
            esac
            require_exact_neon_shaped "$leaf" "$instruction" 16b "$lane_kind" \
              "$arity" "exact NEON ${lane_kind} ${operation} operation"
            forbid_pattern '(^|[[:space:]])(b(\.[a-z]+)?|bl|br|blr|cbz|cbnz|tbz|tbnz)[[:space:]]' "$leaf" \
              "branch or out-of-line helper in ${lane_kind} ${operation} leaf"
        done <scripts/probes/bitwise_codegen_cases.txt
        while read -r lane_kind operation suffix bits lanes signedness; do
            symbol_suffix=
            [ "$suffix" = none ] || symbol_suffix="__${suffix}"
            leaf="$temporary/integer-minmax-leaf-${lane_kind}-${operation}.txt"
            extract_leaf_or_probe "flyology_simd__backends__native__${operation}${symbol_suffix}" \
              "$temporary/native.txt" \
              "integer_minmax_codegen_probe__${lane_kind}_${operation}" \
              "$temporary/integer-minmax-probe.txt" "$leaf"
            require_vector_operand_transfers "$leaf" "$lane_kind" "$operation" 2
            case "$bits" in 8) shape=16b ;; 16) shape=8h ;; 32) shape=4s ;; 64) shape=2d ;; esac
            if [ "$bits" -lt 64 ]; then
                if [ "$signedness" = signed ]; then prefix=s; else prefix=u; fi
                require_exact_neon_shaped "$leaf" "${prefix}${operation}" "$shape" \
                  "$lane_kind" 2 "exact NEON ${shape} ${lane_kind} ${operation}"
            else
                if [ "$signedness" = signed ]; then compare=cmgt; else compare=cmhi; fi
                if [ "$operation" = min ]; then select=bit; else select=bif; fi
                require_exact_neon_shaped "$leaf" "$compare" 2d "$lane_kind" 2 \
                  "exact NEON 64-bit comparison in ${lane_kind} ${operation}"
                require_exact_neon_shaped "$leaf" "$select" 16b "$lane_kind" 2 \
                  "exact NEON 64-bit selection in ${lane_kind} ${operation}"
            fi
            forbid_pattern '(^|[[:space:]])(b(\.[a-z]+)?|bl|br|blr|cbz|cbnz|tbz|tbnz)[[:space:]]' "$leaf" \
              "branch or out-of-line helper in ${lane_kind} ${operation} leaf"
        done <scripts/probes/integer_minmax_codegen_cases.txt
        while read -r lane_kind operation suffix bits lanes signedness; do
            symbol_suffix=
            [ "$suffix" = none ] || symbol_suffix="__${suffix}"
            leaf="$temporary/saturating-arithmetic-leaf-${lane_kind}-${operation}.txt"
            extract_leaf_or_probe "flyology_simd__backends__native__${operation}${symbol_suffix}" \
              "$temporary/native.txt" \
              "saturating_arithmetic_codegen_probe__${lane_kind}_${operation}" \
              "$temporary/saturating-arithmetic-probe.txt" "$leaf"
            require_vector_operand_transfers "$leaf" "$lane_kind" "$operation" 2
            case "$bits" in 8) shape=16b ;; 16) shape=8h ;; 32) shape=4s ;; 64) shape=2d ;; esac
            if [ "$signedness" = signed ]; then prefix=sq; else prefix=uq; fi
            if [ "$operation" = add_saturate ]; then instruction=${prefix}add; else instruction=${prefix}sub; fi
            require_exact_neon_shaped "$leaf" "$instruction" "$shape" "$lane_kind" 2 \
              "exact NEON ${shape} ${lane_kind} ${operation}"
            forbid_pattern '(^|[[:space:]])(b(\.[a-z]+)?|bl|br|blr|cbz|cbnz|tbz|tbnz)[[:space:]]' "$leaf" \
              "branch or out-of-line helper in ${lane_kind} ${operation} leaf"
        done <scripts/probes/saturating_arithmetic_codegen_cases.txt
        while read -r lane_kind operation suffix bits lanes; do
            symbol_suffix=
            [ "$suffix" = none ] || symbol_suffix="__${suffix}"
            leaf="$temporary/lane-arrangement-leaf-${lane_kind}-${operation}.txt"
            extract_leaf_or_probe "flyology_simd__backends__native__${operation}${symbol_suffix}" \
              "$temporary/native.txt" \
              "lane_arrangement_codegen_probe__${lane_kind}_${operation}" \
              "$temporary/lane-arrangement-probe.txt" "$leaf"
            case "$bits" in 8) shape=16b ;; 16) shape=8h ;; 32) shape=4s ;; 64) shape=2d ;; esac
            if [ "$operation" = reverse_lanes ]; then
                require_vector_operand_transfers "$leaf" "$lane_kind" "$operation" 1
            else
                require_vector_operand_transfers "$leaf" "$lane_kind" "$operation" 2
            fi
            case "$operation" in
                reverse_lanes)
                    if [ "$bits" -lt 64 ]; then
                        require_leaf_instruction "(^|[[:space:]])rev64(\.${shape}[[:space:]]|[[:space:]].*\.${shape})" 1 "$leaf" "NEON ${shape} lane reversal in ${lane_kind}"
                    fi
                    require_leaf_instruction '(^|[[:space:]])ext(\.16b[[:space:]]|[[:space:]].*\.16b).*#(0x)?8([^[:xdigit:]]|$)' 1 "$leaf" "eight-byte half exchange in ${lane_kind} reverse"
                    ;;
                interleave_low) instruction=zip1 ;;
                interleave_high) instruction=zip2 ;;
                deinterleave_even) instruction=uzp1 ;;
                deinterleave_odd) instruction=uzp2 ;;
            esac
            if [ "$operation" != reverse_lanes ]; then
                require_leaf_instruction "(^|[[:space:]])${instruction}(\.${shape}[[:space:]]|[[:space:]].*\.${shape}([^[:alnum:]]|$))" 1 "$leaf" "exact NEON ${shape} ${operation} leaf"
            fi
            forbid_pattern '(^|[[:space:]])(b(\.[a-z]+)?|bl)[[:space:]]' "$leaf" \
              "branch or out-of-line helper in ${lane_kind} ${operation} leaf"
        done <scripts/probes/lane_arrangement_codegen_cases.txt
        while read -r lane_kind operation suffix shape x86_shape; do
            symbol_suffix=
            [ "$suffix" = none ] || symbol_suffix="__${suffix}"
            leaf="$temporary/float-binary-leaf-${lane_kind}-${operation}.txt"
            extract_leaf_or_probe "flyology_simd__backends__native__${operation}${symbol_suffix}" \
              "$temporary/native.txt" \
              "float_binary_codegen_probe__${lane_kind}_${operation}" \
              "$temporary/float-binary-probe.txt" "$leaf"
            case "$operation" in
                add) instruction=fadd ;;
                subtract) instruction=fsub ;;
                multiply) instruction=fmul ;;
                divide) instruction=fdiv ;;
                min_number) instruction=fminnm ;;
                max_number) instruction=fmaxnm ;;
            esac
            require_leaf_instruction "(^|[[:space:]])(${instruction}\\.${shape}[[:space:]]|${instruction}[[:space:]].*\\.${shape}([^[:alnum:]]|$))" 1 \
              "$leaf" "exact NEON ${shape} ${operation} leaf"
            forbid_pattern '(^|[[:space:]])(b(\.[a-z]+)?|bl)[[:space:]]' \
              "$leaf" "branch or out-of-line helper in ${lane_kind} ${operation} leaf"
        done <scripts/probes/float_binary_codegen_cases.txt
        while read -r lane_kind operation suffix; do
            if [ "$lane_kind" = u8 ] && [ "$operation" = load_unaligned ]; then
                continue
            fi
            symbol_suffix=
            [ "$suffix" = none ] || symbol_suffix="__${suffix}"
            leaf="$temporary/complete-memory-leaf-${lane_kind}-${operation}.txt"
            extract_leaf_or_probe "flyology_simd__backends__native__${operation}${symbol_suffix}" \
              "$temporary/native.txt" \
              "complete_memory_codegen_probe__${lane_kind}_${operation}" \
              "$temporary/complete-memory-probe.txt" "$leaf"
            if register_operand_memory_family "$lane_kind"; then
                #  A register-operand transfer touches memory exactly once: a
                #  load brings the array in and returns the value in a vector
                #  register, a store takes one and writes the array.  The other
                #  direction is what the address model used to add.
                case "$operation" in
                    load|load_unaligned|load_aligned)
                        require_leaf_instruction '(^|[[:space:]])ldr[[:space:]]+q[0-9]+,[[:space:]]*\[' 1 "$leaf" \
                          "AArch64 ${lane_kind} ${operation} vector load transfer"
                        require_leaf_instruction '(^|[[:space:]])str[[:space:]]+q[0-9]+,[[:space:]]*\[' 0 "$leaf" \
                          "no result store in register-operand ${lane_kind} ${operation} leaf"
                        ;;
                    *)
                        #  No matching absence to assert here: an out-of-line
                        #  store still receives its 128-bit value by reference,
                        #  so the ABI fetches it whatever the assembly does.
                        require_leaf_instruction '(^|[[:space:]])str[[:space:]]+q[0-9]+,[[:space:]]*\[' 1 "$leaf" \
                          "AArch64 ${lane_kind} ${operation} vector store transfer"
                        ;;
                esac
            else
                require_leaf_instruction '(^|[[:space:]])ldr[[:space:]]+q0,[[:space:]]*\[' 1 "$leaf" \
                  "AArch64 ${lane_kind} ${operation} vector load transfer"
                require_leaf_instruction '(^|[[:space:]])str[[:space:]]+q0,[[:space:]]*\[' 1 "$leaf" \
                  "AArch64 ${lane_kind} ${operation} vector store transfer"
            fi
            forbid_pattern 'flyology_simd__(backends__scalar__|wide__)?(load|store)(_unaligned|_aligned)?' \
              "$leaf" "portable, Scalar, or Wide helper in AArch64 ${lane_kind} ${operation} leaf"
        done <scripts/probes/complete_memory_codegen_cases.txt
        for direction in low high; do
            for lane_kind in u8 i8 u16 i16 u32 i32 u64 i64 f32 f64; do
                symbol="slide_codegen_probe__${lane_kind}_${direction}"
                output="$temporary/slide-${lane_kind}-${direction}.txt"
                extract_symbol "$symbol" "$temporary/slide-probe.txt" "$output"
                require_pattern 'ext.*16b' "$output" \
                  "AArch64 immediate lane movement in ${lane_kind} ${direction} caller"
                forbid_pattern 'flyology_simd__(zero|slide_lanes_toward_(low|high))' \
                  "$output" \
                  "portable zero or lane-slide call in ${lane_kind} ${direction} caller"
            done
        done
        #  Both the overload and the instantiation behind it inline, so the
        #  shift lands in the probe that asks for it.  The byte family keeps a
        #  hand-written leaf and is still inspected there.
        extract_symbol 'flyology_simd__backends__native__shift_left_logical' \
          "$temporary/native.txt" "$temporary/u8-shift-left.txt"
        require_pattern 'ushl.*16b' "$temporary/u8-shift-left.txt" \
          'AArch64 ushl in the byte left-shift leaf'
        extract_symbol 'flyology_simd__backends__native__shift_right_logical' \
          "$temporary/native.txt" "$temporary/u8-shift-right.txt"
        require_pattern 'ushl.*16b' "$temporary/u8-shift-right.txt" \
          'AArch64 ushl in the byte right-shift leaf'
        for entry in \
          'i8 16b' 'u16 8h' 'i16 8h' 'u32 4s' 'i32 4s' 'u64 2d' 'i64 2d'; do
            set -- $entry
            kind=$1
            shape=$2
            for direction in left right; do
                caller="$temporary/integer-shift-${kind}-${direction}.txt"
                extract_symbol "integer_shift_codegen_probe__${kind}_${direction}" \
                  "$temporary/integer-shift-probe.txt" "$caller"
                require_pattern "ushl.*${shape}" "$caller" \
                  "AArch64 ushl in the inlined ${kind} ${direction} shift"
                forbid_pattern 'flyology_simd__(zero|shift_(left|right)_logical)' \
                  "$caller" \
                  "portable helper in the inlined ${kind} ${direction} shift"
            done
        done
        for entry in 'i8 16b' 'i16 8h' 'i32 4s' 'i64 2d'; do
            set -- $entry
            lane=$1
            shape=$2
            extract_symbol "integer_shift_codegen_probe__${lane}_arithmetic_right" \
              "$temporary/integer-shift-probe.txt" "$temporary/${lane}-sar.txt"
            require_pattern "sshl.*${shape}" "$temporary/${lane}-sar.txt" \
              "inlined AArch64 arithmetic right shift for ${lane}"
            forbid_pattern '(^|[[:space:]])bl[[:space:]]|flyology_simd__shift_right_arithmetic' \
              "$temporary/${lane}-sar.txt" \
              "portable or out-of-line arithmetic right shift for ${lane}"
        done
        extract_symbol 'construction_codegen_probe__splat_u8' \
          "$temporary/construction-probe.txt" "$temporary/construction-splat-u8.txt"
        require_pattern 'dup\.16b' "$temporary/construction-splat-u8.txt" \
          'inlined AArch64 U8x16 broadcast in the public caller probe'
        forbid_pattern '(^|[[:space:]])bl[[:space:]]|flyology_simd__(backends__native__)?splat' \
          "$temporary/construction-splat-u8.txt" \
          'out-of-line U8x16 broadcast in the AArch64 public caller probe'
        extract_symbol 'flyology_simd__backends__native__zero' \
          "$temporary/native.txt" "$temporary/construction-zero-u8.txt"
        require_count 'mov[[:space:]]+x(0|1),[[:space:]]*#0x?0' 2 \
          "$temporary/construction-zero-u8.txt" \
          'two zero result registers in AArch64 U8x16 Zero'
        #  Zero inlines into whoever asks for it, so the construction is
        #  inspected in the probe rather than in a leaf of its own.
        for kind in i8 u16 i16 u32 i32 u64 i64 f32 f64; do
            extract_symbol "construction_codegen_probe__zero_${kind}" \
              "$temporary/construction-probe.txt" \
              "$temporary/construction-zero-${kind}.txt"
            require_pattern 'movi(\.[0-9]+[bhsd])?.*#0x?0|mov[[:space:]]+x[0-9]+,[[:space:]]*#0x?0' \
              "$temporary/construction-zero-${kind}.txt" \
              "AArch64 vector zero construction for ${kind}"
        done
        #  Splat inlines as well; the broadcast lands in the probe.
        for entry in 'i8 16b' 'u16 8h' 'i16 8h' 'u32 4s' 'i32 4s' \
                     'u64 2d' 'i64 2d' 'f32 4s' 'f64 2d'; do
            set -- $entry
            kind=$1
            shape=$2
            extract_symbol "construction_codegen_probe__splat_${kind}" \
              "$temporary/construction-probe.txt" \
              "$temporary/construction-splat-${kind}.txt"
            require_pattern "dup\.${shape}" \
              "$temporary/construction-splat-${kind}.txt" \
              "AArch64 ${shape} lane broadcast for ${kind}"
        done
        extract_symbol 'flyology_simd__backends__native__horizontal_sum' \
          "$temporary/native.txt" "$temporary/horizontal-sum-u8x16.txt"
        require_pattern 'uaddlv.*16b' \
          "$temporary/horizontal-sum-u8x16.txt" \
          'AArch64 U8x16 exact horizontal sum'
        require_pattern 'umov' "$temporary/horizontal-sum-u8x16.txt" \
          'AArch64 U8x16 exact-sum result transfer'
        forbid_pattern 'flyology_simd__horizontal_sum' \
          "$temporary/horizontal-sum-u8x16.txt" \
          'portable AArch64 Horizontal_Sum call'
        for suffix in '' '__2' '__3' '__4'; do
            extract_symbol "flyology_simd__backends__native__population_count${suffix}" \
              "$temporary/native.txt" "$temporary/population_count${suffix}.txt"
            extract_symbol "flyology_simd__backends__native__first_true${suffix}" \
              "$temporary/native.txt" "$temporary/first_true${suffix}.txt"
            extract_symbol "flyology_simd__backends__native__last_true${suffix}" \
              "$temporary/native.txt" "$temporary/last_true${suffix}.txt"
            require_pattern 'rbit' "$temporary/first_true${suffix}.txt" \
              'AArch64 First_True bit reversal'
            require_pattern 'clz' "$temporary/first_true${suffix}.txt" \
              'AArch64 First_True leading-zero count'
            require_pattern 'clz' "$temporary/last_true${suffix}.txt" \
              'AArch64 Last_True leading-zero count'
            require_pattern '(^|[[:space:]])cnt(\.8b)?[[:space:]]' \
              "$temporary/population_count${suffix}.txt" \
              'AArch64 Population_Count byte population count'
            require_pattern 'uaddlv' "$temporary/population_count${suffix}.txt" \
              'AArch64 Population_Count horizontal sum'
            forbid_pattern 'flyology_simd__first_true|flyology_simd__last_true' \
              "$temporary/first_true${suffix}.txt" \
              'portable AArch64 mask-position call'
            forbid_pattern 'flyology_simd__first_true|flyology_simd__last_true' \
              "$temporary/last_true${suffix}.txt" \
              'portable AArch64 mask-position call'
            forbid_pattern 'flyology_simd__population_count' \
              "$temporary/population_count${suffix}.txt" \
              'portable AArch64 population-count call'
        done
        extract_symbol 'unordered_codegen_probe__f32_unordered' "$temporary/unordered-probe.txt" \
          "$temporary/unordered-f32x4.txt"
        extract_symbol 'unordered_codegen_probe__f64_unordered' "$temporary/unordered-probe.txt" \
          "$temporary/unordered-f64x2.txt"
        for unordered in unordered-f32x4 unordered-f64x2; do
            require_count 'fcmeq' 2 "$temporary/${unordered}.txt" \
              "two self-comparisons in ${unordered}"
            require_pattern 'and.*16b' "$temporary/${unordered}.txt" \
              "ordered-mask conjunction in ${unordered}"
            require_pattern 'mvn.*16b' "$temporary/${unordered}.txt" \
              "unordered-mask inversion in ${unordered}"
            forbid_pattern '(^|[[:space:]])bl[[:space:]]|flyology_simd__unordered' \
              "$temporary/${unordered}.txt" \
              "portable or out-of-line helper in ${unordered}"
        done
        extract_symbol 'native_reduce_add_f32x4' "$temporary/native.txt" \
          "$temporary/reduce-add-f32x4.txt"
        extract_symbol 'native_reduce_add_f64x2' "$temporary/native.txt" \
          "$temporary/reduce-add-f64x2.txt"
        #  Register numbers belong to the allocator now, so the reduction is
        #  evidenced by the shape of the fold rather than by a fixed register.
        require_count 'fadd[[:space:]]+s[0-9]+' 4 "$temporary/reduce-add-f32x4.txt" \
          'four ascending scalar NEON additions in F32x4 Reduce_Add'
        require_count 'fadd[[:space:]]+d[0-9]+' 2 "$temporary/reduce-add-f64x2.txt" \
          'two ascending scalar NEON additions in F64x2 Reduce_Add'
        for reduction in reduce-add-f32x4 reduce-add-f64x2; do
            require_pattern 'movi.*v[0-9]+.*#(0x)?0+([^[:xdigit:]]|$)' \
              "$temporary/${reduction}.txt" \
              "positive-zero accumulator in ${reduction}"
            forbid_pattern '(^|[[:space:]])bl[[:space:]]|flyology_simd__reduce_add' \
              "$temporary/${reduction}.txt" \
              "out-of-line or portable reduction in ${reduction}"
        done
        extract_symbol 'wide_float_reduction_codegen_probe__f32_reduce_add' \
          "$temporary/wide-float-reduction-probe.txt" \
          "$temporary/wide-f32-reduce-add.txt"
        extract_symbol 'wide_float_reduction_codegen_probe__f32_reduce_min_number' \
          "$temporary/wide-float-reduction-probe.txt" \
          "$temporary/wide-f32-reduce-min.txt"
        extract_symbol 'wide_float_reduction_codegen_probe__f64_reduce_max_number' \
          "$temporary/wide-float-reduction-probe.txt" \
          "$temporary/wide-f64-reduce-max.txt"
        extract_symbol 'wide_float_reduction_codegen_probe__f32_reduce_max_number' \
          "$temporary/wide-float-reduction-probe.txt" \
          "$temporary/wide-f32-reduce-max.txt"
        extract_symbol 'wide_float_reduction_codegen_probe__f64_reduce_add' \
          "$temporary/wide-float-reduction-probe.txt" \
          "$temporary/wide-f64-reduce-add.txt"
        extract_symbol 'wide_float_reduction_codegen_probe__f64_reduce_min_number' \
          "$temporary/wide-float-reduction-probe.txt" \
          "$temporary/wide-f64-reduce-min.txt"
        require_count 'fadd[[:space:]]+s' 8 "$temporary/wide-f32-reduce-add.txt" \
          'eight ordered scalar F32 additions in the Wide reduction caller'
        require_count 'fminnm[[:space:]]+s' 7 "$temporary/wide-f32-reduce-min.txt" \
          'seven ordered scalar F32 minimum-number steps in the Wide reduction caller'
        require_count 'fmaxnm[[:space:]]+s' 7 "$temporary/wide-f32-reduce-max.txt" \
          'seven ordered scalar F32 maximum-number steps in the Wide reduction caller'
        require_count 'fadd[[:space:]]+d' 4 "$temporary/wide-f64-reduce-add.txt" \
          'four ordered scalar F64 additions in the Wide reduction caller'
        require_count 'fminnm[[:space:]]+d' 3 "$temporary/wide-f64-reduce-min.txt" \
          'three ordered scalar F64 minimum-number steps in the Wide reduction caller'
        require_count 'fmaxnm[[:space:]]+d' 3 "$temporary/wide-f64-reduce-max.txt" \
          'three ordered scalar F64 maximum-number steps in the Wide reduction caller'
        require_count 'fmov[[:space:]]+s2,[[:space:]]*wzr' 1 \
          "$temporary/wide-f32-reduce-add.txt" \
          'positive-zero start in the Wide F32 Reduce_Add caller'
        require_count 'fmov[[:space:]]+d2,[[:space:]]*xzr' 1 \
          "$temporary/wide-f64-reduce-add.txt" \
          'positive-zero start in the Wide F64 Reduce_Add caller'
        for extrema in wide-f32-reduce-min wide-f32-reduce-max; do
            require_count 'fmov[[:space:]]+s2,[[:space:]]*s0' 1 \
              "$temporary/${extrema}.txt" \
              "lane-zero start in ${extrema}"
        done
        for extrema in wide-f64-reduce-min wide-f64-reduce-max; do
            require_count 'fmov[[:space:]]+d2,[[:space:]]*d0' 1 \
              "$temporary/${extrema}.txt" \
              "lane-zero start in ${extrema}"
        done
        for floating_reduction_probe in \
          wide-f32-reduce-add wide-f32-reduce-min wide-f32-reduce-max \
          wide-f64-reduce-add wide-f64-reduce-min wide-f64-reduce-max; do
            require_count 'ldr[[:space:]]+q' 2 \
              "$temporary/${floating_reduction_probe}.txt" \
              "two Wide input-half loads in ${floating_reduction_probe}"
            forbid_pattern '(^|[[:space:]])bl[[:space:]]|flyology_simd__(wide__)?reduce_' \
              "$temporary/${floating_reduction_probe}.txt" \
              "out-of-line or portable reduction in ${floating_reduction_probe}"
        done
        require_pattern 'cmeq' "$(native_and_probes)" 'NEON byte comparison'
        require_pattern 'add.*16b' "$(native_and_probes)" 'NEON wrapping byte add'
        require_pattern 'sub.*16b' "$(native_and_probes)" 'NEON wrapping byte subtract'
        require_pattern 'uqadd' "$(native_and_probes)" 'NEON saturating byte add'
        require_pattern 'uqsub' "$(native_and_probes)" 'NEON saturating byte subtract'
        require_pattern 'orr.*16b' "$(native_and_probes)" 'NEON byte OR'
        require_pattern 'eor.*16b' "$(native_and_probes)" 'NEON byte XOR'
        require_pattern 'mvn.*16b' "$(native_and_probes)" 'NEON byte complement'
        require_pattern 'ushl.*16b' "$(native_and_probes)" 'NEON defined byte shifts'
        require_pattern 'cmhi.*16b' "$(native_and_probes)" 'NEON unsigned ordered comparison'
        require_pattern 'cmhs.*16b' "$(native_and_probes)" 'NEON unsigned inclusive comparison'
        require_pattern 'bsl.*16b' "$(native_and_probes)" 'NEON masked selection'
        require_pattern 'rev64.*16b' "$(native_and_probes)" 'NEON byte reversal'
        require_pattern 'zip1.*16b' "$(native_and_probes)" 'NEON low interleave'
        require_pattern 'zip2.*16b' "$(native_and_probes)" 'NEON high interleave'
        require_pattern 'uzp1.*16b' "$(native_and_probes)" 'NEON even deinterleave'
        require_pattern 'uzp2.*16b' "$(native_and_probes)" 'NEON odd deinterleave'
        require_pattern 'uminv.*16b' "$(native_and_probes)" 'NEON unsigned byte minimum reduction'
        require_pattern 'umaxv.*16b' "$(native_and_probes)" 'NEON unsigned byte maximum reduction'
        while read -r operation instruction_pattern matching_symbols; do
            bind_u8_selected_operation \
              "$temporary/u8-value-${operation}.txt" \
              "$instruction_pattern" "$matching_symbols" \
              "$temporary/native.txt" \
              "$temporary/u8-native-${operation}.txt" \
              "AArch64 U8 ${operation} caller"
            require_exact_u8_operation \
              "$temporary/u8-value-${operation}.txt" \
              "$temporary/u8-native-${operation}.txt" \
              "$instruction_pattern" "$operation" \
              "AArch64 U8 ${operation}"
        done <<'EOF'
add_wrap add.*16b add_wrap|neon_add_wrap
subtract_wrap sub.*16b subtract_wrap|neon_subtract_wrap
multiply_wrap mul.*16b multiply_wrap|neon_multiply_wrap
add_saturate uqadd.*16b add_saturate|neon_add_saturate
subtract_saturate uqsub.*16b subtract_saturate|neon_subtract_saturate
bitwise_and and.*16b bitwise_and|neon_bitwise_and
bitwise_or orr.*16b bitwise_or|neon_bitwise_or
bitwise_xor eor.*16b bitwise_xor|neon_bitwise_xor
bitwise_not mvn.*16b bitwise_not|neon_bitwise_not
equal cmeq.*16b equal|equal_bits
less_than cmhi.*16b less_than|greater_bits
less_equal cmhs.*16b less_equal|greater_equal_bits
greater_than cmhi.*16b greater_than|greater_bits
greater_equal cmhs.*16b greater_equal|greater_equal_bits
select_value bsl.*16b select_value
min umin.*16b min|neon_min
max umax.*16b max|neon_max
reduce_add_wrap addv.*16b reduce_add_wrap|native_reduce_add_wrap_u8x16
reduce_min uminv.*16b reduce_min|native_reduce_min_u8x16
reduce_max umaxv.*16b reduce_max|native_reduce_max_u8x16
reverse_bytes rev64.*16b reverse_bytes|neon_reverse_bytes
reverse_lanes rev64.*16b reverse_lanes|neon_reverse_bytes
interleave_low zip1.*16b interleave_low|neon_interleave_low
interleave_high zip2.*16b interleave_high|neon_interleave_high
deinterleave_even uzp1.*16b deinterleave_even|neon_deinterleave_even
deinterleave_odd uzp2.*16b deinterleave_odd|neon_deinterleave_odd
EOF
        for operation in equal less_than less_equal greater_than greater_equal; do
            require_count 'uaddlv.*8b' 2 \
              "$temporary/u8-native-${operation}.txt" \
              "two byte-half mask sums in AArch64 U8 ${operation}"
            require_count 'umov' 2 "$temporary/u8-native-${operation}.txt" \
              "two mask-half transfers in AArch64 U8 ${operation}"
            require_pattern 'ext.*16b.*#(0x)?8' \
              "$temporary/u8-native-${operation}.txt" \
              "high mask-half extraction in AArch64 U8 ${operation}"
        done
        require_pattern 'cmtst.*16b' \
          "$temporary/u8-native-select_value.txt" \
          'compact-mask expansion in AArch64 U8 Select_Value'
        require_pattern 'bsl.*16b' "$temporary/u8-native-select_value.txt" \
          'bit selection in AArch64 U8 Select_Value'
        for operation in reverse_bytes reverse_lanes; do
            require_pattern 'ext.*16b.*#(0x)?8' \
              "$temporary/u8-native-${operation}.txt" \
              "byte-half exchange in AArch64 U8 ${operation}"
        done
        require_pattern 'umov' "$temporary/u8-native-reduce_add_wrap.txt" \
          'result transfer in AArch64 U8 Reduce_Add_Wrap'
        extract_symbol 'native_reduce_add_wrap_i32x4' "$temporary/native.txt" "$temporary/reduce_add_i32.txt"
        extract_symbol 'native_reduce_min_u16x8' "$temporary/native.txt" "$temporary/reduce_min_u16.txt"
        extract_symbol 'native_reduce_max_i8x16' "$temporary/native.txt" "$temporary/reduce_max_i8.txt"
        extract_symbol 'native_reduce_add_wrap_u64x2' "$temporary/native.txt" "$temporary/reduce_add_u64.txt"
        extract_symbol 'native_reduce_min_i64x2' "$temporary/native.txt" "$temporary/reduce_min_i64.txt"
        extract_symbol 'native_reduce_max_u64x2' "$temporary/native.txt" "$temporary/reduce_max_u64.txt"
        require_pattern 'addv.*4s' "$temporary/reduce_add_i32.txt" 'NEON signed-32 wrapping reduction'
        require_pattern 'uminv.*8h' "$temporary/reduce_min_u16.txt" 'NEON unsigned-16 minimum reduction'
        require_pattern 'smaxv.*16b' "$temporary/reduce_max_i8.txt" 'NEON signed-byte maximum reduction'
        require_pattern 'addp.*2d' "$temporary/reduce_add_u64.txt" 'NEON unsigned-64 wrapping reduction'
        require_pattern 'dup.*2d.*v[0-9]+.*\[1\]' "$temporary/reduce_min_i64.txt" 'NEON signed-64 reduction lane broadcast'
        require_pattern 'cmgt.*2d' "$temporary/reduce_min_i64.txt" 'NEON signed-64 minimum comparison'
        require_pattern 'bit.*16b' "$temporary/reduce_min_i64.txt" 'NEON signed-64 minimum selection'
        require_pattern 'dup.*2d.*v[0-9]+.*\[1\]' "$temporary/reduce_max_u64.txt" 'NEON unsigned-64 reduction lane broadcast'
        require_pattern 'cmhi.*2d' "$temporary/reduce_max_u64.txt" 'NEON unsigned-64 maximum comparison'
        require_pattern 'bif.*16b' "$temporary/reduce_max_u64.txt" 'NEON unsigned-64 maximum selection'
        #  Inspect every 128-bit integer-reduction leaf.  The public caller
        #  probe above binds each overload to one exact selected symbol; these
        #  checks bind every selected symbol to its operation-specific NEON
        #  instruction sequence.
        while read -r lane_kind suffix shape lane_letter prefix; do
            symbol_suffix=
            [ "$suffix" = none ] || symbol_suffix="__${suffix}"
            for operation in reduce_add_wrap reduce_min reduce_max; do
                output="$temporary/integer_reduction_leaf_${lane_kind}_${operation}.txt"
                extract_symbol "flyology_simd__backends__native__${operation}${symbol_suffix}" \
                  "$temporary/native.txt" "$output"
                forbid_pattern 'flyology_simd__(backends__scalar__)?reduce_|flyology_simd__wide__' \
                  "$output" "portable, Scalar, or Wide helper in ${lane_kind} ${operation} leaf"
                forbid_pattern '(^|[[:space:]])(b|bl)[[:space:]].*flyology_simd__' \
                  "$output" "out-of-line Flyology helper in ${lane_kind} ${operation} leaf"
            done
            if [ "$lane_kind" = u8 ]; then
                #  Short enough to inline, so the byte reduction leaves no leaf
                #  of its own; the fold is evidenced wherever it landed.  addv
                #  over sixteen byte lanes wraps, which is the defined result.
                require_pattern '(^|[[:space:]])(addv\.16b[[:space:]]|addv[[:space:]].*16b([^[:alnum:]]|$))' \
                  "$(native_and_probes)" \
                  'unsigned-byte wrapping sum in U8 Reduce_Add_Wrap'
            elif [ "$shape" = 2d ]; then
                require_count '(^|[[:space:]])(addp\.2d[[:space:]]|addp[[:space:]].*2d([^[:alnum:]]|$))' 1 \
                  "$temporary/integer_reduction_leaf_${lane_kind}_reduce_add_wrap.txt" \
                  "one exact 64-bit pairwise sum in ${lane_kind} Reduce_Add_Wrap"
            else
                require_count "(^|[[:space:]])(addv\\.${shape}[[:space:]]|addv[[:space:]].*${shape}([^[:alnum:]]|$))" 1 \
                  "$temporary/integer_reduction_leaf_${lane_kind}_reduce_add_wrap.txt" \
                  "one exact packed sum in ${lane_kind} Reduce_Add_Wrap"
            fi
            if [ "$shape" = 2d ]; then
                compare=cmhi
                [ "$prefix" = s ] && compare=cmgt
                for operation in reduce_min reduce_max; do
                    output="$temporary/integer_reduction_leaf_${lane_kind}_${operation}.txt"
                    require_count '(^|[[:space:]])(dup\.2d[[:space:]].*\[1\]|dup[[:space:]].*2d.*\[1\])' 1 \
                      "$output" "one high-lane broadcast in ${lane_kind} ${operation}"
                    require_count "(^|[[:space:]])(${compare}\\.2d[[:space:]]|${compare}[[:space:]].*2d([^[:alnum:]]|$))" 1 \
                      "$output" "one 64-bit comparison in ${lane_kind} ${operation}"
                done
                require_at_most '(^|[[:space:]])(bit\.16b[[:space:]]|bit[[:space:]].*16b([^[:alnum:]]|$))' 1 \
                  "$temporary/integer_reduction_leaf_${lane_kind}_reduce_min.txt" \
                  "one minimum selection in ${lane_kind} Reduce_Min"
                require_at_most '(^|[[:space:]])(bif\.16b[[:space:]]|bif[[:space:]].*16b([^[:alnum:]]|$))' 1 \
                  "$temporary/integer_reduction_leaf_${lane_kind}_reduce_max.txt" \
                  "one maximum selection in ${lane_kind} Reduce_Max"
            else
                require_count "(^|[[:space:]])(${prefix}minv\\.${shape}[[:space:]]|${prefix}minv[[:space:]].*${shape}([^[:alnum:]]|$))" 1 \
                  "$temporary/integer_reduction_leaf_${lane_kind}_reduce_min.txt" \
                  "one exact packed minimum in ${lane_kind} Reduce_Min"
                require_count "(^|[[:space:]])(${prefix}maxv\\.${shape}[[:space:]]|${prefix}maxv[[:space:]].*${shape}([^[:alnum:]]|$))" 1 \
                  "$temporary/integer_reduction_leaf_${lane_kind}_reduce_max.txt" \
                  "one exact packed maximum in ${lane_kind} Reduce_Max"
            fi
            for operation in reduce_add_wrap reduce_min reduce_max; do
                output="$temporary/integer_reduction_leaf_${lane_kind}_${operation}.txt"
                if [ "$lane_kind:$operation" = u8:reduce_add_wrap ]; then
                    require_pattern '(^|[[:space:]])umov(\.h)?[[:space:]]' \
                      "$output" 'widened sum transfer in U8 Reduce_Add_Wrap'
                else
                    #  A lane-to-register move is spelled umov for the narrow
                    #  widths and mov for the ones that fill the destination.
                    require_pattern "(^|[[:space:]])(str[[:space:]]+${lane_letter}0|u?mov\\.${lane_letter}[[:space:]]|umov[[:space:]])" \
                      "$output" "result transfer in ${lane_kind} ${operation}"
                fi
            done
        done <<'EOF'
u8  none 16b b u
i8  2    16b b s
u16 3    8h  h u
i16 4    8h  h s
u32 5    4s  s u
i32 6    4s  s s
u64 7    2d  d u
i64 8    2d  d s
EOF
        extract_symbol 'native_multiply_wrap_u64x2' "$temporary/native.txt" "$temporary/multiply_u64.txt"
        extract_symbol 'native_multiply_wrap_i64x2' "$temporary/native.txt" "$temporary/multiply_i64.txt"
        for multiply_probe in multiply_u64 multiply_i64; do
            require_count '(^|[[:space:]])uzp1(\.4s)?[[:space:]]+v[0-9]+' 2 "$temporary/${multiply_probe}.txt" \
              "two low-word deinterleaves in ${multiply_probe}"
            require_count '(^|[[:space:]])uzp2(\.4s)?[[:space:]]+v[0-9]+' 2 "$temporary/${multiply_probe}.txt" \
              "two high-word deinterleaves in ${multiply_probe}"
            require_count '(^|[[:space:]])umull(\.2d)?[[:space:]]+v[0-9]+' 1 "$temporary/${multiply_probe}.txt" \
              "one low-word full product in ${multiply_probe}"
            require_count '(^|[[:space:]])mul(\.2s)?[[:space:]]+v[0-9]+' 1 "$temporary/${multiply_probe}.txt" \
              "one first cross product in ${multiply_probe}"
            require_count '(^|[[:space:]])mla(\.2s)?[[:space:]]+v[0-9]+' 1 "$temporary/${multiply_probe}.txt" \
              "one second cross product in ${multiply_probe}"
            require_count '(^|[[:space:]])shll(\.2d)?[[:space:]]+v[0-9]+.*#(32|0x20)([^[:xdigit:]]|$)' 1 \
              "$temporary/${multiply_probe}.txt" \
              "32-bit cross-product shift in ${multiply_probe}"
            require_count '(^|[[:space:]])add(\.2d)?[[:space:]]+v[0-9]+' 1 "$temporary/${multiply_probe}.txt" \
              "one modulo-64 product combination in ${multiply_probe}"
            forbid_pattern '(^|[[:space:]])bl[[:space:]]|flyology_simd__multiply_wrap' \
              "$temporary/${multiply_probe}.txt" \
              "out-of-line or portable multiplication in ${multiply_probe}"
        done
        #  The selection leaf may inline into the comparison probe or stay
        #  behind one tail call; look for whichever body carries the work.
        for entry in 'i8 i8x16' 'u16 u16x8' 'i16 i16x8' 'u32 u32x4' 'i32 i32x4' \
                     'u64 u64x2' 'i64 i64x2' 'f32 f32x4' 'f64 f64x2'; do
            set -- $entry
            select_kind=$1
            select_vector=$2
            extract_leaf_or_probe "native_select_${select_vector}" \
              "$temporary/native.txt" \
              "comparison_codegen_probe__selected_${select_kind}_select_value" \
              "$temporary/comparison-probe.txt" \
              "$temporary/select_${select_kind}.txt"
            require_count '(^|[[:space:]])cmtst(\.(16b|8h|4s|2d))?[[:space:]]+v[0-9]+' 1 \
              "$temporary/select_${select_kind}.txt" \
              "one lane-mask expansion in select_${select_kind}"
            require_at_most '(^|[[:space:]])bsl(\.16b)?[[:space:]]+v[0-9]+' 1 \
              "$temporary/select_${select_kind}.txt" \
              "one NEON bit selection in select_${select_kind}"
            forbid_pattern '(^|[[:space:]])bl[[:space:]]|flyology_simd__select_value' \
              "$temporary/select_${select_kind}.txt" \
              "out-of-line or portable selection in select_${select_kind}"
        done
        extract_leaf_or_probe 'native_table_lookup_u8x16' "$temporary/native.txt" \
          'table_lookup_codegen_probe__lookup' "$temporary/table-lookup-probe.txt" \
          "$temporary/table_lookup.txt"
        require_pattern 'tbl.*16b' "$temporary/table_lookup.txt" 'NEON byte-table lookup'
        forbid_pattern '(^|[[:space:]])bl[[:space:]]|flyology_simd__table_lookup' \
          "$temporary/table_lookup.txt" 'portable or out-of-line AArch64 Table_Lookup helper'
        for lane_kind in u8 i8 u16 i16 u32 i32 f32 u64 i64 f64; do
            for operation in compress expand; do
                extract_symbol "permute_codegen_probe__${lane_kind}_${operation}" "$temporary/permute-probe.txt" "$temporary/${lane_kind}_${operation}.txt"
                require_pattern 'tbl.*16b' "$temporary/${lane_kind}_${operation}.txt" "inlined NEON ${lane_kind} ${operation} caller"
            done
        done
        forbid_pattern 'flyology_simd__backends__native__(compress|expand)' "$temporary/permute-probe.txt" 'compression backend call in caller probe'
        for lane_kind in u8 i8 u16 i16 u32 i32 f32 u64 i64 f64; do
            extract_symbol "permute_codegen_probe__${lane_kind}_permute" "$temporary/permute-probe.txt" "$temporary/permute_${lane_kind}.txt"
            require_pattern 'tbl.*16b' "$temporary/permute_${lane_kind}.txt" "NEON ${lane_kind} public lane permutation"
            extract_symbol "permute_codegen_probe__${lane_kind}_permute_2" "$temporary/permute-probe.txt" "$temporary/permute_2_${lane_kind}.txt"
            require_count 'tbl(\.16b)?[[:space:]]+v[0-9]+,.*\{[[:space:]]*v[0-9]+[[:space:]]*\},[[:space:]]*v[0-9]+' 1 "$temporary/permute_2_${lane_kind}.txt" "one NEON ${lane_kind} left-source table lookup"
            require_count 'tbx(\.16b)?[[:space:]]+v[0-9]+,.*\{[[:space:]]*v[0-9]+[[:space:]]*\},[[:space:]]*v[0-9]+' 1 "$temporary/permute_2_${lane_kind}.txt" "one NEON ${lane_kind} right-source table extension"
        done
        forbid_pattern 'flyology_simd__backends__native__permute_lanes' "$temporary/permute-probe.txt" 'lane-permutation backend call in caller probe'
        extract_symbol 'wide_codegen_probe__u8_add' "$temporary/wide-probe.txt" "$temporary/wide_u8_add.txt"
        extract_symbol 'wide_codegen_probe__f32_multiply' "$temporary/wide-probe.txt" "$temporary/wide_f32_multiply.txt"
        for precision in f32 f64; do
            for operation in add subtract multiply divide min_number max_number; do
                extract_symbol "wide_codegen_probe__${precision}_${operation}" \
                  "$temporary/wide-probe.txt" \
                  "$temporary/wide_${precision}_${operation}.txt"
            done
        done
        extract_symbol 'wide_codegen_probe__f32_to_u32_bits' "$temporary/wide-probe.txt" "$temporary/wide_f32_to_u32.txt"
        extract_symbol 'wide_codegen_probe__u8_widen_low' "$temporary/wide-probe.txt" "$temporary/wide_u8_widen.txt"
        extract_symbol 'wide_codegen_probe__u16_narrow_saturate' "$temporary/wide-probe.txt" "$temporary/wide_u16_narrow.txt"
        extract_symbol 'wide_codegen_probe__i32_to_f32' "$temporary/wide-probe.txt" "$temporary/wide_i32_to_f32.txt"
        extract_symbol 'wide_codegen_probe__u8_table_lookup' "$temporary/wide-probe.txt" "$temporary/wide_u8_table_lookup.txt"
        extract_symbol 'wide_codegen_probe__u8_horizontal_sum' "$temporary/wide-probe.txt" "$temporary/wide_u8_horizontal_sum.txt"
        extract_symbol 'wide_codegen_probe__u8_compress' "$temporary/wide-probe.txt" "$temporary/wide_u8_compress.txt"
        extract_symbol 'wide_codegen_probe__u16_expand' "$temporary/wide-probe.txt" "$temporary/wide_u16_expand.txt"
        extract_symbol 'wide_codegen_probe__f32_compress' "$temporary/wide-probe.txt" "$temporary/wide_f32_compress.txt"
        extract_symbol 'wide_codegen_probe__f64_expand' "$temporary/wide-probe.txt" "$temporary/wide_f64_expand.txt"
        extract_symbol 'wide_codegen_probe__u8_permute' "$temporary/wide-probe.txt" "$temporary/wide_u8_permute.txt"
        extract_symbol 'wide_codegen_probe__u16_permute_2' "$temporary/wide-probe.txt" "$temporary/wide_u16_permute_2.txt"
        extract_symbol 'wide_codegen_probe__f32_permute' "$temporary/wide-probe.txt" "$temporary/wide_f32_permute.txt"
        extract_symbol 'wide_codegen_probe__f64_permute_2' "$temporary/wide-probe.txt" "$temporary/wide_f64_permute_2.txt"
        extract_symbol 'wide_codegen_probe__u8_reverse' "$temporary/wide-probe.txt" "$temporary/wide_u8_reverse.txt"
        extract_symbol 'wide_codegen_probe__u16_interleave_low' "$temporary/wide-probe.txt" "$temporary/wide_u16_interleave.txt"
        extract_symbol 'wide_codegen_probe__f32_deinterleave_odd' "$temporary/wide-probe.txt" "$temporary/wide_f32_deinterleave.txt"
        extract_symbol 'wide_codegen_probe__f64_slide_low_one' "$temporary/wide-probe.txt" "$temporary/wide_f64_slide.txt"
        for lane_kind in u8 i8; do
            for operation in equal less less_equal greater greater_equal select; do
                extract_symbol "wide_codegen_probe__${lane_kind}_${operation}" \
                  "$temporary/wide-probe.txt" \
                  "$temporary/wide_${lane_kind}_${operation}.txt"
            done
        done
        for permute_probe in wide_u8_permute wide_f32_permute; do
            require_count 'tbl(\.16b)?[[:space:]]+v[0-9]+,.*\{[[:space:]]*v[0-9]+,[[:space:]]*v[0-9]+[[:space:]]*\},[[:space:]]*v[0-9]+' 2 \
              "$temporary/${permute_probe}.txt" \
              "two-register TBL operations in AArch64 ${permute_probe} caller"
            forbid_pattern 'flyology_simd__wide__(permute_mechanism|native)__permute_lanes|flyology_simd__(__wide)?__(extract|from_lanes)' \
              "$temporary/${permute_probe}.txt" \
              "per-lane or dispatcher call in AArch64 ${permute_probe} caller"
        done
        for permute_probe in wide_u16_permute_2 wide_f64_permute_2; do
            require_count 'tbl(\.16b)?[[:space:]]+v[0-9]+,.*\{[[:space:]]*v[0-9]+,[[:space:]]*v[0-9]+,[[:space:]]*v[0-9]+,[[:space:]]*v[0-9]+[[:space:]]*\},[[:space:]]*v[0-9]+' 2 \
              "$temporary/${permute_probe}.txt" \
              "four-register TBL operations in AArch64 ${permute_probe} caller"
            forbid_pattern 'flyology_simd__wide__(permute_mechanism|native)__permute_lanes|flyology_simd__(__wide)?__(extract|from_lanes)' \
              "$temporary/${permute_probe}.txt" \
              "per-lane or dispatcher call in AArch64 ${permute_probe} caller"
        done
        for movement_probe in wide_u8_reverse wide_f64_slide; do
            require_count 'tbl(\.16b)?[[:space:]]+v[0-9]+,.*\{[[:space:]]*v[0-9]+,[[:space:]]*v[0-9]+[[:space:]]*\},[[:space:]]*v[0-9]+' 2 \
              "$temporary/${movement_probe}.txt" \
              "two-register TBL operations in AArch64 ${movement_probe} caller"
        done
        for movement_probe in wide_u16_interleave wide_f32_deinterleave; do
            require_count 'tbl(\.16b)?[[:space:]]+v[0-9]+,.*\{[[:space:]]*v[0-9]+,[[:space:]]*v[0-9]+,[[:space:]]*v[0-9]+,[[:space:]]*v[0-9]+[[:space:]]*\},[[:space:]]*v[0-9]+' 2 \
              "$temporary/${movement_probe}.txt" \
              "four-register TBL operations in AArch64 ${movement_probe} caller"
        done
        for movement_probe in wide_u8_reverse wide_u16_interleave wide_f32_deinterleave wide_f64_slide; do
            forbid_pattern 'flyology_simd__wide__(permute_mechanism|native)__(reverse_lanes|interleave|deinterleave|slide_lanes)|flyology_simd__(__wide)?__(extract|from_lanes)' \
              "$temporary/${movement_probe}.txt" \
              "per-lane or dispatcher call in AArch64 ${movement_probe} caller"
        done
        require_at_most '(^|[[:space:]])bl[[:space:]]' 2 "$temporary/wide_u8_add.txt" 'two inlined NEON byte-add leaves in wide caller'
        require_at_most '(^|[[:space:]])bl[[:space:]]' 2 "$temporary/wide_f32_multiply.txt" 'two NEON F32-multiply leaves in wide caller'
        require_at_most '(^|[[:space:]])bl[[:space:]]' 2 "$temporary/wide_f32_to_u32.txt" 'two NEON F32-to-U32 bit-cast leaves in wide caller'
        require_at_most '(^|[[:space:]])bl[[:space:]]' 2 "$temporary/wide_u8_widen.txt" 'two NEON byte-widen leaves in wide caller'
        require_at_most '(^|[[:space:]])bl[[:space:]]' 2 "$temporary/wide_u16_narrow.txt" 'two NEON U16-narrow leaves in wide caller'
        require_at_most '(^|[[:space:]])bl[[:space:]]' 2 "$temporary/wide_i32_to_f32.txt" 'two NEON I32-to-F32 conversion leaves in wide caller'
        require_at_most '(^|[[:space:]])bl[[:space:]]' 1 "$temporary/wide_u8_table_lookup.txt" 'one target-selected 32-lane table-lookup mechanism in wide caller'
        require_at_most '(^|[[:space:]])bl[[:space:]]' 2 "$temporary/wide_u8_horizontal_sum.txt" 'two exact byte-sum leaves in wide caller'
        for compact_probe in wide_u8_compress wide_u16_expand wide_f32_compress wide_f64_expand; do
            require_count 'tbl(\.16b)?[[:space:]]+v[0-9]+,.*\{[[:space:]]*v[0-9]+,[[:space:]]*v[0-9]+[[:space:]]*\},[[:space:]]*v[0-9]+' 2 \
              "$temporary/${compact_probe}.txt" \
              "two-register TBL operations in AArch64 ${compact_probe} caller"
            forbid_pattern 'flyology_simd__wide__(compact_mechanism|native)__(compress|expand)|flyology_simd__(__wide)?__(extract|from_lanes|test)' \
              "$temporary/${compact_probe}.txt" \
              "per-lane or dispatcher call in AArch64 ${compact_probe} caller"
        done
        for lane_kind in u8 i8 u16 i16 u32 i32 u64 i64 f32 f64; do
            for operation in compress expand; do
                extract_symbol "wide_compact_codegen_probe__${lane_kind}_${operation}" \
                  "$temporary/wide-compact-probe.txt" \
                  "$temporary/wide_compact_${lane_kind}_${operation}.txt"
                require_count 'tbl(\.16b)?[[:space:]]+v[0-9]+,.*\{[[:space:]]*v[0-9]+,[[:space:]]*v[0-9]+[[:space:]]*\},[[:space:]]*v[0-9]+' 2 \
                  "$temporary/wide_compact_${lane_kind}_${operation}.txt" \
                  "two-register TBL operations in AArch64 ${lane_kind} ${operation} caller"
                forbid_pattern 'flyology_simd__(__wide)?__to_bit_mask|flyology_simd__backends__native__to_bit_mask' \
                  "$temporary/wide_compact_${lane_kind}_${operation}.txt" \
                  "out-of-line mask extraction in AArch64 ${lane_kind} ${operation} caller"
                forbid_pattern 'flyology_simd__wide__(compact_mechanism|native)__(compress|expand)|flyology_simd__(__wide)?__(extract|from_lanes|test)' \
                  "$temporary/wide_compact_${lane_kind}_${operation}.txt" \
                  "per-lane or dispatcher call in AArch64 ${lane_kind} ${operation} caller"
            done
        done
        require_at_most 'flyology_simd__' 0 \
          "$temporary/wide-compact-object-undefined.txt" \
          'no Flyology operation remains unresolved in the AArch64 Wide compact object'
        forbid_pattern 'flyology_simd__wide__to_bit_mask|flyology_simd__wide__(compress|expand)|flyology_simd__wide__native__' \
          "$temporary/wide-compact-object-undefined.txt" \
          'portable or public Wide helper retained in the AArch64 Wide compact object'
        for vector_kind in u8x32 i8x32 u16x16 i16x16 u32x8 i32x8 u64x4 i64x4 f32x8 f64x4; do
            for operation in permute_1 reverse slide_low slide_high; do
                extract_symbol "wide_movement_codegen_probe__${vector_kind}_${operation}" \
                  "$temporary/wide-movement-probe.txt" \
                  "$temporary/wide_movement_${vector_kind}_${operation}.txt"
                require_count 'tbl(\.16b)?[[:space:]]+v[0-9]+,.*\{[[:space:]]*v[0-9]+,[[:space:]]*v[0-9]+[[:space:]]*\},[[:space:]]*v[0-9]+' 2 \
                  "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                  "two two-register TBL operations in AArch64 ${vector_kind} ${operation} caller"
                forbid_pattern 'flyology_simd__wide__(extract|from_lanes|permute_lanes|reverse_lanes|interleave_|deinterleave_|slide_lanes_)' \
                  "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                  "call or per-lane helper in AArch64 ${vector_kind} ${operation} caller"
            done
            for operation in permute_2 interleave_low interleave_high deinterleave_even deinterleave_odd; do
                extract_symbol "wide_movement_codegen_probe__${vector_kind}_${operation}" \
                  "$temporary/wide-movement-probe.txt" \
                  "$temporary/wide_movement_${vector_kind}_${operation}.txt"
                require_count 'tbl(\.16b)?[[:space:]]+v[0-9]+,.*\{[[:space:]]*v[0-9]+,[[:space:]]*v[0-9]+,[[:space:]]*v[0-9]+,[[:space:]]*v[0-9]+[[:space:]]*\},[[:space:]]*v[0-9]+' 2 \
                  "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                  "two four-register TBL operations in AArch64 ${vector_kind} ${operation} caller"
                forbid_pattern 'flyology_simd__wide__(extract|from_lanes|permute_lanes|reverse_lanes|interleave_|deinterleave_|slide_lanes_)' \
                  "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                  "call or per-lane helper in AArch64 ${vector_kind} ${operation} caller"
            done
        done
        require_count 'cmeq.*16b' 2 "$temporary/wide_u8_equal.txt" \
          'two NEON equality operations in the composed Wide U8 caller'
        forbid_pattern '(^|[[:space:]])bl[[:space:]]' "$temporary/wide_u8_equal.txt" \
          'out-of-line helper retained in the composed Wide U8 equality caller'
        for operation in less less_equal greater greater_equal; do
            require_at_most '(^|[[:space:]])bl[[:space:]]' 2 \
              "$temporary/wide_u8_${operation}.txt" \
              "two selected NEON operations in composed Wide U8 ${operation} caller"
            require_at_most '(^|[[:space:]])bl[[:space:]]' 2 \
              "$temporary/wide_i8_${operation}.txt" \
              "two selected NEON operations in composed Wide I8 ${operation} caller"
        done
        require_at_most '(^|[[:space:]])bl[[:space:]]' 2 "$temporary/wide_i8_equal.txt" \
          'two selected NEON operations in composed Wide I8 equality caller'
        require_at_most '(^|[[:space:]])bl[[:space:]]' 2 "$temporary/wide_u8_select.txt" \
          'two selected NEON operations in composed Wide U8 selection caller'
        require_at_most '(^|[[:space:]])bl[[:space:]]' 2 "$temporary/wide_i8_select.txt" \
          'two selected operations in composed Wide I8 selection caller'
        extract_symbol 'table_lookup_half' "$temporary/wide-lookup.txt" "$temporary/wide_lookup_leaf.txt"
        require_pattern 'tbl(\.16b)?[[:space:]]+v[0-9]+,.*\{[[:space:]]*v[0-9]+,[[:space:]]*v[0-9]+[[:space:]]*\},[[:space:]]*v[0-9]+' "$temporary/wide_lookup_leaf.txt" 'AArch64 32-entry byte-table lookup leaf'
        require_route_or_inlined 'flyology_simd__backends__native__(neon_)?add_wrap' "$temporary/wide-undefined.txt" 'wide U8 addition calls selected 128-bit native leaves after mechanism inlining'
        require_route_or_inlined 'flyology_simd__backends__native__native_(add|subtract|multiply|divide)_(f32x4|f64x2)' "$temporary/wide-undefined.txt" 'wide floating arithmetic calls selected 128-bit native leaves'
        require_route_or_inlined 'flyology_simd__backends__native__bit_cast' "$temporary/wide-undefined.txt" 'wide F32 bit cast calls the selected 128-bit native leaf'
        require_route_or_inlined 'flyology_simd__backends__native__widen_(low|high)' "$temporary/wide-undefined.txt" 'wide byte widening calls selected 128-bit native leaves'
        require_route_or_inlined 'flyology_simd__backends__native__narrow_saturate' "$temporary/wide-undefined.txt" 'wide U16 narrowing calls selected 128-bit native leaves'
        require_route_or_inlined 'flyology_simd__backends__native__convert_round' "$temporary/wide-undefined.txt" 'wide integer conversion calls selected 128-bit native leaves'
        require_pattern 'flyology_simd__wide__lookup_mechanism__table_lookup_32' "$temporary/wide-undefined.txt" 'wide lookup calls the target-selected lookup mechanism'
        require_route_or_inlined 'flyology_simd__backends__native__horizontal_sum' "$temporary/wide-undefined.txt" 'wide exact byte sum calls the selected 128-bit native leaf'
        require_route_or_inlined 'flyology_simd__backends__native__(greater|greater_equal|compare_|select_value)' "$temporary/wide-undefined.txt" 'wide byte predicates call selected 128-bit native operations'
        require_native_route 'flyology_simd__backends__native__((neon_)?add_wrap|native_(add|subtract|multiply|divide)_(f32x4|f64x2)|bit_cast|widen_low|widen_high|narrow_saturate|convert_round|horizontal_sum|greater_bits|greater_equal_bits|compare_(greater(_equal)?_)?i8x16|select_value)|flyology_simd__wide__lookup_mechanism__table_lookup_32' 22 "$temporary/wide-undefined.txt" "$temporary/wide-probe.txt" 'only the intended native primitive classes remain unresolved from the wide probe'
        forbid_pattern 'flyology_simd__(wide__)?(add_wrap|add|subtract|multiply|divide|bit_cast|widen_(low|high)|narrow_saturate|convert_round|table_lookup|horizontal_sum)' "$temporary/wide-undefined.txt" 'scalar or Wide primitive call from the native wide probe'
        forbid_pattern 'flyology_simd__wide__native__(add_wrap|multiply|bit_cast|widen_(low|high)|narrow_saturate|convert_round|table_lookup|horizontal_sum)' "$temporary/wide-probe.txt" 'wide native dispatcher call in caller probe'
        extract_symbol 'slide_codegen_probe__u8_toward_low' "$temporary/slide-probe.txt" "$temporary/probe_u8_low.txt"
        extract_symbol 'slide_codegen_probe__u8_toward_high' "$temporary/slide-probe.txt" "$temporary/probe_u8_high.txt"
        extract_symbol 'slide_codegen_probe__u16_toward_low' "$temporary/slide-probe.txt" "$temporary/probe_u16_low.txt"
        extract_symbol 'slide_codegen_probe__u32_toward_low' "$temporary/slide-probe.txt" "$temporary/probe_u32_low.txt"
        extract_symbol 'slide_codegen_probe__f32_toward_low' "$temporary/slide-probe.txt" "$temporary/probe_f32_low.txt"
        extract_symbol 'slide_codegen_probe__f32_toward_high' "$temporary/slide-probe.txt" "$temporary/probe_f32_high.txt"
        extract_symbol 'slide_codegen_probe__f64_toward_high' "$temporary/slide-probe.txt" "$temporary/probe_f64_high.txt"
        require_pattern 'ext.*#(0x)?0*1([^[:xdigit:]]|$)' "$temporary/probe_u8_low.txt" 'constant U8 slide toward low in caller'
        require_pattern 'ext.*#(0x)?0*f([^[:xdigit:]]|$)' "$temporary/probe_u8_high.txt" 'constant U8 slide toward high in caller'
        require_pattern 'ext.*#(0x)?0*2([^[:xdigit:]]|$)' "$temporary/probe_u16_low.txt" 'constant U16 lane scaling in caller'
        require_pattern 'ext.*#(0x)?0*4([^[:xdigit:]]|$)' "$temporary/probe_u32_low.txt" 'constant U32 lane scaling in caller'
        require_pattern 'ext.*#(0x)?0*4([^[:xdigit:]]|$)' "$temporary/probe_f32_low.txt" 'constant F32 slide toward low in caller'
        require_pattern 'ext.*#(0x)?0*c([^[:xdigit:]]|$)' "$temporary/probe_f32_high.txt" 'constant F32 slide toward high in caller'
        require_pattern 'ext.*#(0x)?0*8([^[:xdigit:]]|$)' "$temporary/probe_f64_high.txt" 'constant F64 lane scaling in caller'
        forbid_pattern 'flyology_simd__backends__native__slide_lanes' "$temporary/slide-probe.txt" 'lane-slide dispatcher call in constant-count probe'
        require_pattern 'ldr[[:space:]]+q[0-9]+' "$(native_and_probes)" '128-bit unaligned load'
        require_pattern 'uaddlv' "$(native_and_probes)" 'vector mask/sum reduction'
        require_pattern 'sqadd.*(16b|8h|4s|2d)' "$(native_and_probes)" 'signed saturating arithmetic'
        require_pattern 'mul.*(16b|8h|4s)' "$(native_and_probes)" 'wrapping integer multiplication'
        require_pattern 'add.*8h' "$(native_and_probes)" '16-bit lane arithmetic'
        require_pattern 'add.*4s' "$(native_and_probes)" '32-bit lane arithmetic'
        require_pattern 'add.*2d' "$(native_and_probes)" '64-bit lane arithmetic'
        require_pattern 'cmgt.*(16b|8h|4s|2d)' "$(native_and_probes)" 'signed ordered comparison'
        require_pattern 'sshl.*(16b|8h|4s|2d)' "$(native_and_probes)" 'arithmetic right shift'
        require_pattern 'fadd.*(4s|2d)' "$(native_and_probes)" 'floating addition'
        require_pattern 'fmul.*(4s|2d)' "$(native_and_probes)" 'floating multiplication'
        require_pattern 'fdiv.*(4s|2d)' "$(native_and_probes)" 'floating division'
        require_pattern 'fminnm.*(4s|2d)' "$(native_and_probes)" 'IEEE minimum-number operation'
        require_pattern 'fmaxnm.*(4s|2d)' "$(native_and_probes)" 'IEEE maximum-number operation'
        require_pattern 'fminnm[[:space:]]+s[0-9]+,' "$(native_and_probes)" 'ordered F32 minimum-number reduction'
        require_pattern 'fmaxnm[[:space:]]+s[0-9]+,' "$(native_and_probes)" 'ordered F32 maximum-number reduction'
        require_pattern 'fminnm[[:space:]]+d[0-9]+,' "$(native_and_probes)" 'ordered F64 minimum-number reduction'
        require_pattern 'fmaxnm[[:space:]]+d[0-9]+,' "$(native_and_probes)" 'ordered F64 maximum-number reduction'
        require_pattern 'fcmeq.*(4s|2d)' "$(native_and_probes)" 'floating comparison'
        require_pattern '(uxtl|ushll)2?.*(8h|4s|2d)' "$(native_and_probes)" 'unsigned integer widening'
        require_pattern '(sxtl|sshll)2?.*(8h|4s|2d)' "$(native_and_probes)" 'signed integer widening'
        require_pattern 'fcvtl2?.*2d' "$(native_and_probes)" 'floating-point widening'
        require_pattern 'fcvtn2?.*(2s|4s)' "$(native_and_probes)" 'floating-point narrowing'
        require_pattern 'scvtf.*4s' "$(native_and_probes)" 'signed 32-bit integer-to-floating conversion'
        require_pattern 'scvtf.*2d' "$(native_and_probes)" 'signed 64-bit integer-to-floating conversion'
        require_pattern 'ucvtf.*4s' "$(native_and_probes)" 'unsigned 32-bit integer-to-floating conversion'
        require_pattern 'ucvtf.*2d' "$(native_and_probes)" 'unsigned 64-bit integer-to-floating conversion'
        require_pattern 'fcvtzs.*4s' "$(native_and_probes)" 'binary32-to-signed-32 truncating saturating conversion'
        require_pattern 'fcvtzs.*2d' "$(native_and_probes)" 'binary64-to-signed-64 truncating saturating conversion'
        require_pattern 'fcvtzu.*4s' "$(native_and_probes)" 'binary32-to-unsigned-32 truncating saturating conversion'
        require_pattern 'fcvtzu.*2d' "$(native_and_probes)" 'binary64-to-unsigned-64 truncating saturating conversion'
        extract_symbol 'integer_conversion_codegen_probe__i8_u8_convert_saturate' "$temporary/integer-conversion-probe.txt" "$temporary/i8_to_u8.txt"
        extract_symbol 'integer_conversion_codegen_probe__u8_i8_convert_saturate' "$temporary/integer-conversion-probe.txt" "$temporary/u8_to_i8.txt"
        extract_symbol 'integer_conversion_codegen_probe__i16_u16_convert_saturate' "$temporary/integer-conversion-probe.txt" "$temporary/i16_to_u16.txt"
        extract_symbol 'integer_conversion_codegen_probe__u16_i16_convert_saturate' "$temporary/integer-conversion-probe.txt" "$temporary/u16_to_i16.txt"
        extract_symbol 'integer_conversion_codegen_probe__i32_u32_convert_saturate' "$temporary/integer-conversion-probe.txt" "$temporary/i32_to_u32.txt"
        extract_symbol 'integer_conversion_codegen_probe__u32_i32_convert_saturate' "$temporary/integer-conversion-probe.txt" "$temporary/u32_to_i32.txt"
        extract_symbol 'integer_conversion_codegen_probe__i64_u64_convert_saturate' "$temporary/integer-conversion-probe.txt" "$temporary/i64_to_u64.txt"
        extract_symbol 'integer_conversion_codegen_probe__u64_i64_convert_saturate' "$temporary/integer-conversion-probe.txt" "$temporary/u64_to_i64.txt"
        require_pattern 'movi.*v[0-9]+.*#(0x)?0+([,[:space:]]|$)' "$temporary/i8_to_u8.txt" 'signed-byte conversion zero construction'
        require_pattern 'smax.*16b' "$temporary/i8_to_u8.txt" 'signed-byte to unsigned-byte saturation'
        require_pattern 'movi.*v[0-9]+.*#(0xff|255)([,[:space:]]|$)' "$temporary/u8_to_i8.txt" 'signed-byte maximum all-ones construction'
        require_pattern 'ushr.*16b.*#(0x)?1([,[:space:]]|$)' "$temporary/u8_to_i8.txt" 'signed-byte maximum construction'
        require_pattern 'umin.*16b' "$temporary/u8_to_i8.txt" 'unsigned-byte to signed-byte saturation'
        require_pattern 'movi.*v[0-9]+.*#(0x)?0+([,[:space:]]|$)' "$temporary/i16_to_u16.txt" 'signed-16 conversion zero construction'
        require_pattern 'smax.*8h' "$temporary/i16_to_u16.txt" 'signed-16 to unsigned-16 saturation'
        require_pattern 'movi.*v[0-9]+.*#(0xff|255)([,[:space:]]|$)' "$temporary/u16_to_i16.txt" 'signed-16 maximum all-ones construction'
        require_pattern 'ushr.*8h.*#(0x)?1([,[:space:]]|$)' "$temporary/u16_to_i16.txt" 'signed-16 maximum construction'
        require_pattern 'umin.*8h' "$temporary/u16_to_i16.txt" 'unsigned-16 to signed-16 saturation'
        require_pattern 'movi.*v[0-9]+.*#(0x)?0+([,[:space:]]|$)' "$temporary/i32_to_u32.txt" 'signed-32 conversion zero construction'
        require_pattern 'smax.*4s' "$temporary/i32_to_u32.txt" 'signed-32 to unsigned-32 saturation'
        require_pattern 'movi.*v[0-9]+.*#(0xff|255)([,[:space:]]|$)' "$temporary/u32_to_i32.txt" 'signed-32 maximum all-ones construction'
        require_pattern 'ushr.*4s.*#(0x)?1([,[:space:]]|$)' "$temporary/u32_to_i32.txt" 'signed-32 maximum construction'
        require_pattern 'umin.*4s' "$temporary/u32_to_i32.txt" 'unsigned-32 to signed-32 saturation'
        require_pattern 'cmge.*2d.*#(0x)?0+([,[:space:]]|$)' "$temporary/i64_to_u64.txt" 'signed-64 nonnegative mask'
        require_pattern 'and.*16b' "$temporary/i64_to_u64.txt" 'signed-64 to unsigned-64 saturation'
        require_pattern 'movi.*v[0-9]+.*#(0xff|255)([,[:space:]]|$)' "$temporary/u64_to_i64.txt" 'signed-64 maximum all-ones construction'
        require_pattern 'ushr.*2d.*#(0x)?1([,[:space:]]|$)' "$temporary/u64_to_i64.txt" 'signed-64 maximum construction'
        require_pattern 'cmhi.*2d' "$temporary/u64_to_i64.txt" 'unsigned-64 clamp mask'
        require_pattern 'bsl.*16b' "$temporary/u64_to_i64.txt" 'unsigned-64 clamp selection'
        require_pattern 'mov(\.16b)?[[:space:]]+v[0-9]+,[[:space:]]*v[0-9]+' "$temporary/u64_to_i64.txt" 'unsigned-64 conversion result move'
        require_pattern '(^|[[:space:]])xtn2?\..*(16b|8h|4s)' "$(native_and_probes)" 'truncating integer narrowing'
        require_pattern '(^|[[:space:]])uqxtn2?\..*(16b|8h|4s)' "$(native_and_probes)" 'unsigned saturating narrowing'
        require_pattern '(^|[[:space:]])sqxtn2?\..*(16b|8h|4s)' "$(native_and_probes)" 'signed saturating narrowing'
        require_pattern '(^|[[:space:]])sqxtun2?\..*(16b|8h|4s)' "$(native_and_probes)" 'signed-to-unsigned saturating narrowing'
        while read -r kind operation source target suffix arity; do
            [ -n "$kind" ] || continue
            selected_symbol=$operation
            if [ "$suffix" != none ]; then
                selected_symbol="${operation}__${suffix}"
            fi
            leaf="$temporary/aarch_integer_conversion_${kind}_${operation}.txt"
            #  The conversion leaves take and return registers and inline into
            #  their probe, so there is no fixed-register transfer left to
            #  count; the exact instruction is asserted below instead.
            extract_leaf_or_probe "flyology_simd__backends__native__${selected_symbol}" \
              "$temporary/native.txt" \
              "integer_conversion_codegen_probe__${kind}_${operation}" \
              "$temporary/integer-conversion-probe.txt" "$leaf"
            forbid_pattern '(^|[[:space:]])(b(\.[a-z]+)?|bl|br|blr|cbz|cbnz|tbz|tbnz)[[:space:]]' \
              "$leaf" "branch or helper in ${kind} ${operation} leaf"

            case "$operation" in
                widen_low|widen_high)
                    case "$source" in
                        u8x16) mnemonic=ushll; shape=8h ;;
                        i8x16) mnemonic=sshll; shape=8h ;;
                        u16x8) mnemonic=ushll; shape=4s ;;
                        i16x8) mnemonic=sshll; shape=4s ;;
                        u32x4) mnemonic=ushll; shape=2d ;;
                        i32x4) mnemonic=sshll; shape=2d ;;
                    esac
                    [ "$operation" = widen_high ] && mnemonic="${mnemonic}2"
                    require_leaf_instruction "(^|[[:space:]])${mnemonic}\\.${shape}[[:space:]]" 1 \
                      "$leaf" "exact ${mnemonic}.${shape} in ${kind} ${operation}"
                    ;;
                narrow_truncate|narrow_saturate)
                    case "$target" in
                        u8x16|i8x16) low_shape=8b; high_shape=16b ;;
                        u16x8|i16x8) low_shape=4h; high_shape=8h ;;
                        u32x4|i32x4) low_shape=2s; high_shape=4s ;;
                    esac
                    if [ "$operation" = narrow_truncate ]; then
                        mnemonic=xtn
                    elif echo "$source:$target" | grep -Eq '^i.*:u'; then
                        mnemonic=sqxtun
                    elif echo "$source" | grep -Eq '^i'; then
                        mnemonic=sqxtn
                    else
                        mnemonic=uqxtn
                    fi
                    require_leaf_instruction "(^|[[:space:]])${mnemonic}\\.${low_shape}[[:space:]]" 1 \
                      "$leaf" "exact ${mnemonic}.${low_shape} low half in ${kind} ${operation}"
                    require_leaf_instruction "(^|[[:space:]])${mnemonic}2\\.${high_shape}[[:space:]]" 1 \
                      "$leaf" "exact ${mnemonic}2.${high_shape} high half in ${kind} ${operation}"
                    ;;
                convert_saturate)
                    case "$source:$target" in
                        i8x16:u8x16) required='movi.*v[0-9]+.*#(0x)?0+|smax.*16b' ;;
                        u8x16:i8x16) required='movi.*v[0-9]+.*#(0xff|255)|ushr.*16b.*#(0x)?1|umin.*16b' ;;
                        i16x8:u16x8) required='movi.*v[0-9]+.*#(0x)?0+|smax.*8h' ;;
                        u16x8:i16x8) required='movi.*v[0-9]+.*#(0xff|255)|ushr.*8h.*#(0x)?1|umin.*8h' ;;
                        i32x4:u32x4) required='movi.*v[0-9]+.*#(0x)?0+|smax.*4s' ;;
                        u32x4:i32x4) required='movi.*v[0-9]+.*#(0xff|255)|ushr.*4s.*#(0x)?1|umin.*4s' ;;
                        i64x2:u64x2) required='cmge.*2d.*#(0x)?0+|and.*16b' ;;
                        u64x2:i64x2) required='movi.*v[0-9]+.*#(0xff|255)|ushr.*2d.*#(0x)?1|cmhi.*2d|bsl.*16b|mov(\.16b)?[[:space:]]+v[0-9]+,[[:space:]]*v[0-9]+' ;;
                    esac
                    printf '%s\n' "$required" | tr '|' '\n' | while read -r instruction; do
                        require_at_least "(^|[[:space:]])${instruction}" 1 "$leaf" \
                          "exact conversion step ${instruction} in ${kind} ${operation}"
                    done
                    ;;
            esac
        done <scripts/probes/integer_conversion_codegen_cases.txt
        require_pattern 'ldr[[:space:]]+q[0-9]+' "$temporary/algorithm.txt" \
          'inlined vector load in representative loop'
        require_pattern 'cmeq.*16b' "$temporary/algorithm.txt" \
          'inlined NEON comparison in representative loop'
        require_pattern 'uaddlv' "$temporary/algorithm.txt" \
          'inlined compact-mask extraction in representative loop'
        extract_symbol 'flyology_simd__algorithms__native__find_first_of' \
          "$temporary/algorithm.txt" "$temporary/find-first-of.txt"
        require_pattern 'ldr[[:space:]]+q[0-9]+' \
          "$temporary/find-first-of.txt" \
          'fused small-set NEON vector load'
        require_pattern 'cmeq.*16b' "$temporary/find-first-of.txt" \
          'fused small-set NEON comparisons'
        require_pattern 'uaddlv' "$temporary/find-first-of.txt" \
          'fused small-set NEON mask extraction'
        extract_symbol \
          'flyology_simd__algorithms__native__find_first_difference' \
          "$temporary/algorithm.txt" "$temporary/find-first-difference.txt"
        require_pattern 'ldr[[:space:]]+q[0-9]+' \
          "$temporary/find-first-difference.txt" \
          'fused two-buffer NEON vector loads'
        require_pattern 'cmeq.*16b' \
          "$temporary/find-first-difference.txt" \
          'fused two-buffer NEON byte comparison'
        require_pattern 'uaddlv' \
          "$temporary/find-first-difference.txt" \
          'fused two-buffer NEON mask extraction'
        require_pattern '(^|[[:space:]])mvn[[:space:]]' \
          "$temporary/find-first-difference.txt" \
          'complemented NEON equality mask'
        forbid_pattern \
          'bl.*flyology_simd__backends__native__(load_unaligned|equal|to_bit_mask)' \
          "$temporary/find-first-difference.txt" \
          'out-of-line primitive in the Native difference loop'
        extract_symbol 'flyology_simd__algorithms__native__count_in_range' \
          "$temporary/algorithm.txt" "$temporary/count-in-range.txt"
        require_pattern 'ldr[[:space:]]+q[0-9]+' \
          "$temporary/count-in-range.txt" \
          'Native range-count NEON vector load'
        require_at_most 'flyology_simd__backends__native__greater_equal' 1 \
          "$temporary/count-in-range.txt" \
          'one selected lower-bound comparison in Native range count'
        require_at_most 'flyology_simd__backends__native__less_equal' 1 \
          "$temporary/count-in-range.txt" \
          'one selected upper-bound comparison in Native range count'
        require_at_most 'flyology_simd__backends__native__mask_and' 1 \
          "$temporary/count-in-range.txt" \
          'one selected mask intersection in Native range count'
        require_pattern 'cnt.*8b' "$temporary/count-in-range.txt" \
          'NEON population count in Native range count'
        forbid_pattern 'bl.*equal_mask' "$temporary/native.txt" 'out-of-line mask helper call'
        ;;
    x86_64)
        while read -r lane_kind operation suffix bits lanes; do
            symbol_suffix=
            [ "$suffix" = none ] || symbol_suffix="__${suffix}"
            leaf="$temporary/wrapping-arithmetic-leaf-${lane_kind}-${operation}.txt"
            extract_leaf_or_probe "flyology_simd__backends__native__${operation}${symbol_suffix}" \
              "$temporary/native.txt" \
              "wrapping_arithmetic_codegen_probe__${lane_kind}_${operation}" \
              "$temporary/wrapping-arithmetic-probe.txt" "$leaf"
            require_at_most '(^|[[:space:]])movdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%xmm0' 1 "$leaf" \
              "left operand transfer in ${lane_kind} ${operation} leaf"
            require_at_most '(^|[[:space:]])movdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%xmm1' 1 "$leaf" \
              "right operand transfer in ${lane_kind} ${operation} leaf"
            require_leaf_instruction '(^|[[:space:]])movdqu[[:space:]]+%xmm[0-9]+,[[:space:]]*[^,]*\([^)]*\)' 0 "$leaf" \
              "no result store in register-operand ${lane_kind} ${operation} leaf"
            case "$bits:$operation" in
                8:add_wrap) require_leaf_instruction '(^|[[:space:]])paddb[[:space:]]' 1 "$leaf" "exact SSE2 ${lane_kind} add" ;;
                8:subtract_wrap) require_leaf_instruction '(^|[[:space:]])psubb[[:space:]]' 1 "$leaf" "exact SSE2 ${lane_kind} subtract" ;;
                16:add_wrap) require_leaf_instruction '(^|[[:space:]])paddw[[:space:]]' 1 "$leaf" "exact SSE2 ${lane_kind} add" ;;
                16:subtract_wrap) require_leaf_instruction '(^|[[:space:]])psubw[[:space:]]' 1 "$leaf" "exact SSE2 ${lane_kind} subtract" ;;
                32:add_wrap) require_leaf_instruction '(^|[[:space:]])paddd[[:space:]]' 1 "$leaf" "exact SSE2 ${lane_kind} add" ;;
                32:subtract_wrap) require_leaf_instruction '(^|[[:space:]])psubd[[:space:]]' 1 "$leaf" "exact SSE2 ${lane_kind} subtract" ;;
                64:add_wrap) require_leaf_instruction '(^|[[:space:]])paddq[[:space:]]' 1 "$leaf" "exact SSE2 ${lane_kind} add" ;;
                64:subtract_wrap) require_leaf_instruction '(^|[[:space:]])psubq[[:space:]]' 1 "$leaf" "exact SSE2 ${lane_kind} subtract" ;;
                8:multiply_wrap)
                    require_leaf_instruction '(^|[[:space:]])punpcklbw[[:space:]]' 2 "$leaf" "two low-byte widening steps in ${lane_kind} multiplication"
                    require_leaf_instruction '(^|[[:space:]])punpckhbw[[:space:]]' 2 "$leaf" "two high-byte widening steps in ${lane_kind} multiplication"
                    require_leaf_instruction '(^|[[:space:]])pmullw[[:space:]]' 2 "$leaf" "two widened products in ${lane_kind} multiplication"
                    require_leaf_instruction '(^|[[:space:]])pand[[:space:]]' 2 "$leaf" "two low-byte masks in ${lane_kind} multiplication"
                    require_leaf_instruction '(^|[[:space:]])packuswb[[:space:]]' 1 "$leaf" "byte repacking in ${lane_kind} multiplication"
                    require_leaf_instruction '(^|[[:space:]])pxor[[:space:]]' 1 "$leaf" "zero construction in ${lane_kind} multiplication"
                    require_leaf_instruction '(^|[[:space:]])pcmpeqd[[:space:]]' 1 "$leaf" "all-ones mask construction in ${lane_kind} multiplication"
                    require_leaf_instruction '(^|[[:space:]])psrlw[[:space:]].*\$(0x0*8|8)([,[:space:]]|$)' 1 "$leaf" "low-byte mask derivation in ${lane_kind} multiplication"
                    ;;
                16:multiply_wrap) require_leaf_instruction '(^|[[:space:]])pmullw[[:space:]]' 1 "$leaf" "exact SSE2 ${lane_kind} multiplication" ;;
                32:multiply_wrap)
                    require_leaf_instruction '(^|[[:space:]])pmuludq[[:space:]]' 2 "$leaf" "two even-dword products in ${lane_kind} multiplication"
                    require_leaf_instruction '(^|[[:space:]])psrldq[[:space:]].*\$(0x0*4|4)([,[:space:]]|$)' 2 "$leaf" "two four-byte odd-dword advances in ${lane_kind} multiplication"
                    require_leaf_instruction '(^|[[:space:]])pshufd[[:space:]].*\$(0x0*88|136)([,[:space:]]|$)' 2 "$leaf" "two 0x88 dword product packings in ${lane_kind} multiplication"
                    require_leaf_instruction '(^|[[:space:]])punpckldq[[:space:]]' 1 "$leaf" "dword product merge in ${lane_kind} multiplication"
                    ;;
                64:multiply_wrap)
                    require_leaf_instruction '(^|[[:space:]])pmuludq[[:space:]]' 3 "$leaf" "three partial products in ${lane_kind} multiplication"
                    require_leaf_instruction '(^|[[:space:]])pshufd[[:space:]].*\$(0x0*b1|177)([,[:space:]]|$)' 2 "$leaf" "two 0xb1 cross-part broadcasts in ${lane_kind} multiplication"
                    require_leaf_instruction '(^|[[:space:]])paddq[[:space:]]' 2 "$leaf" "two partial-product additions in ${lane_kind} multiplication"
                    require_leaf_instruction '(^|[[:space:]])psllq[[:space:]].*\$(0x20|32)' 1 "$leaf" "32-bit cross-product shift in ${lane_kind} multiplication"
                    ;;
            esac
            forbid_pattern '(^|[[:space:]])(callq?|jmpq?)[[:space:]]' "$leaf" \
              "branch or out-of-line helper in ${lane_kind} ${operation} leaf"
        done <scripts/probes/wrapping_arithmetic_codegen_cases.txt
        while read -r lane_kind operation suffix bits lanes arity; do
            symbol_suffix=
            [ "$suffix" = none ] || symbol_suffix="__${suffix}"
            leaf="$temporary/bitwise-leaf-${lane_kind}-${operation}.txt"
            if [ "$lane_kind" = u8 ] && [ "$operation" = bitwise_and ]; then
                extract_symbol 'bitwise_codegen_probe__u8_bitwise_and' \
                  "$temporary/bitwise-probe.txt" "$leaf"
            else
                extract_leaf_or_probe "flyology_simd__backends__native__${operation}${symbol_suffix}" \
                  "$temporary/native.txt" \
                  "bitwise_codegen_probe__${lane_kind}_${operation}" \
                  "$temporary/bitwise-probe.txt" "$leaf"
            fi
            require_at_most '(^|[[:space:]])movdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%xmm0' 1 "$leaf" \
              "left operand transfer in ${lane_kind} ${operation} leaf"
            if [ "$arity" -eq 2 ]; then
                require_at_most '(^|[[:space:]])movdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%xmm1' 1 "$leaf" \
                  "right operand transfer in ${lane_kind} ${operation} leaf"
            else
                require_leaf_instruction '(^|[[:space:]])movdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%xmm1' 0 "$leaf" \
                  "no second memory operand in ${lane_kind} ${operation} leaf"
            fi
            require_leaf_instruction '(^|[[:space:]])movdqu[[:space:]]+%xmm[0-9]+,[[:space:]]*[^,]*\([^)]*\)' 0 "$leaf" \
              "no result store in register-operand ${lane_kind} ${operation} leaf"
            case "$operation" in
                bitwise_and) require_leaf_instruction '(^|[[:space:]])pand[[:space:]]+%xmm[0-9]+,[[:space:]]*%xmm[0-9]+' 1 "$leaf" "exact SSE2 ${lane_kind} AND" ;;
                bitwise_or) require_leaf_instruction '(^|[[:space:]])por[[:space:]]+%xmm[0-9]+,[[:space:]]*%xmm[0-9]+' 1 "$leaf" "exact SSE2 ${lane_kind} OR" ;;
                bitwise_xor) require_leaf_instruction '(^|[[:space:]])pxor[[:space:]]+%xmm[0-9]+,[[:space:]]*%xmm[0-9]+' 1 "$leaf" "exact SSE2 ${lane_kind} XOR" ;;
                bitwise_not)
                    require_leaf_instruction '(^|[[:space:]])pcmpeqd[[:space:]]+%xmm1,[[:space:]]*%xmm1' 1 "$leaf" "all-one construction in ${lane_kind} NOT"
                    require_leaf_instruction '(^|[[:space:]])pxor[[:space:]]+%xmm[0-9]+,[[:space:]]*%xmm[0-9]+' 1 "$leaf" "exact SSE2 ${lane_kind} NOT"
                    ;;
            esac
            forbid_pattern '(^|[[:space:]])(callq?|j[a-z]+)[[:space:]]' "$leaf" \
              "branch or out-of-line helper in ${lane_kind} ${operation} leaf"
        done <scripts/probes/bitwise_codegen_cases.txt
        while read -r lane_kind operation suffix bits lanes signedness; do
            symbol_suffix=
            [ "$suffix" = none ] || symbol_suffix="__${suffix}"
            leaf="$temporary/integer-minmax-leaf-${lane_kind}-${operation}.txt"
            extract_leaf_or_probe "flyology_simd__backends__native__${operation}${symbol_suffix}" \
              "$temporary/native.txt" \
              "integer_minmax_codegen_probe__${lane_kind}_${operation}" \
              "$temporary/integer-minmax-probe.txt" "$leaf"
            require_at_most '(^|[[:space:]])movdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%xmm0' 1 "$leaf" \
              "left operand transfer in ${lane_kind} ${operation} leaf"
            require_at_most '(^|[[:space:]])movdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%xmm1' 1 "$leaf" \
              "right operand transfer in ${lane_kind} ${operation} leaf"
            case "$lane_kind" in u8|i16) result_register=xmm0 ;; *) result_register=xmm2 ;; esac
            require_leaf_instruction "(^|[[:space:]])movdqu[[:space:]]+%xmm[0-9]+,[[:space:]]*[^,]*\([^)]*\)" 0 "$leaf" \
              "no result store in register-operand ${lane_kind} ${operation} leaf"
            case "${lane_kind}:${operation}" in
                u8:min) require_leaf_instruction '(^|[[:space:]])pminub[[:space:]]+%xmm[0-9]+,[[:space:]]*%xmm[0-9]+' 1 "$leaf" "exact SSE2 U8x16 Min" ;;
                u8:max) require_leaf_instruction '(^|[[:space:]])pmaxub[[:space:]]+%xmm[0-9]+,[[:space:]]*%xmm[0-9]+' 1 "$leaf" "exact SSE2 U8x16 Max" ;;
                i16:min) require_leaf_instruction '(^|[[:space:]])pminsw[[:space:]]+%xmm[0-9]+,[[:space:]]*%xmm[0-9]+' 1 "$leaf" "exact SSE2 I16x8 Min" ;;
                i16:max) require_leaf_instruction '(^|[[:space:]])pmaxsw[[:space:]]+%xmm[0-9]+,[[:space:]]*%xmm[0-9]+' 1 "$leaf" "exact SSE2 I16x8 Max" ;;
                *)
                    case "$bits" in 8) compare=pcmpgtb ;; 16) compare=pcmpgtw ;; 32|64) compare=pcmpgtd ;; esac
                    if [ "$bits" -eq 64 ]; then compare_count=2; else compare_count=1; fi
                    require_count "(^|[[:space:]])${compare}[[:space:]]" "$compare_count" "$leaf" \
                      "exact SSE2 comparison in ${lane_kind} ${operation}"
                    require_leaf_instruction '(^|[[:space:]])pmovmskb[[:space:]]' 1 "$leaf" \
                      "compact comparison mask in ${lane_kind} ${operation}"
                    require_leaf_instruction '(^|[[:space:]])pandn[[:space:]]' 1 "$leaf" \
                      "false selection arm in ${lane_kind} ${operation}"
                    if [ "$bits" -eq 64 ]; then
                        require_leaf_instruction '(^|[[:space:]])pcmpeqd[[:space:]]' 3 "$leaf" \
                          "equality-gated dword comparison in ${lane_kind} ${operation}"
                        require_leaf_instruction '(^|[[:space:]])pshufd[[:space:]]' 4 "$leaf" \
                          "adjacent-dword broadcasts in ${lane_kind} ${operation}"
                        require_leaf_instruction '(^|[[:space:]])pand[[:space:]]' 3 "$leaf" \
                          "64-bit comparison and selection masks in ${lane_kind} ${operation}"
                        require_leaf_instruction '(^|[[:space:]])por[[:space:]]' 2 "$leaf" \
                          "64-bit comparison and selection merges in ${lane_kind} ${operation}"
                        if [ "$signedness" = unsigned ]; then expected_xor=6; else expected_xor=4; fi
                        require_count '(^|[[:space:]])pxor[[:space:]]' "$expected_xor" "$leaf" \
                          "signedness and mask transforms in ${lane_kind} ${operation}"
                    else
                        require_leaf_instruction '(^|[[:space:]])pand[[:space:]]' 2 "$leaf" \
                          "comparison and true selection masks in ${lane_kind} ${operation}"
                        require_leaf_instruction '(^|[[:space:]])por[[:space:]]' 1 "$leaf" \
                          "selection merge in ${lane_kind} ${operation}"
                        if [ "$signedness" = unsigned ]; then expected_xor=4; else expected_xor=2; fi
                        require_count '(^|[[:space:]])pxor[[:space:]]' "$expected_xor" "$leaf" \
                          "signedness and mask transforms in ${lane_kind} ${operation}"
                        case "$bits" in
                            8)
                                require_leaf_instruction '(^|[[:space:]])punpcklbw[[:space:]]' 1 "$leaf" "byte mask expansion in ${lane_kind} ${operation}"
                                require_leaf_instruction '(^|[[:space:]])punpcklwd[[:space:]]' 1 "$leaf" "word mask expansion in ${lane_kind} ${operation}"
                                require_leaf_instruction '(^|[[:space:]])punpckldq[[:space:]]' 1 "$leaf" "dword mask expansion in ${lane_kind} ${operation}"
                                require_leaf_instruction '(^|[[:space:]])pcmpeqb[[:space:]]' 1 "$leaf" "byte mask materialization in ${lane_kind} ${operation}"
                                require_leaf_instruction '(^|[[:space:]])pcmpeqd[[:space:]]' 1 "$leaf" "byte mask inversion in ${lane_kind} ${operation}"
                                ;;
                            16)
                                require_leaf_instruction '(^|[[:space:]])pcmpeqw[[:space:]]' 1 "$leaf" "word mask materialization in ${lane_kind} ${operation}"
                                require_leaf_instruction '(^|[[:space:]])pcmpeqd[[:space:]]' 1 "$leaf" "word mask inversion in ${lane_kind} ${operation}"
                                require_leaf_instruction '(^|[[:space:]])pshufd[[:space:]]' 1 "$leaf" "word mask broadcast in ${lane_kind} ${operation}"
                                ;;
                            32)
                                require_leaf_instruction '(^|[[:space:]])pcmpeqd[[:space:]]' 2 "$leaf" "dword mask materialization in ${lane_kind} ${operation}"
                                require_leaf_instruction '(^|[[:space:]])pshufd[[:space:]]' 1 "$leaf" "dword mask broadcast in ${lane_kind} ${operation}"
                                ;;
                        esac
                    fi
                    ;;
            esac
            forbid_pattern '(^|[[:space:]])(callq?|j[a-z]+)[[:space:]]' "$leaf" \
              "branch or out-of-line helper in ${lane_kind} ${operation} leaf"
        done <scripts/probes/integer_minmax_codegen_cases.txt
        while read -r lane_kind operation suffix bits lanes signedness; do
            symbol_suffix=
            [ "$suffix" = none ] || symbol_suffix="__${suffix}"
            leaf="$temporary/saturating-arithmetic-leaf-${lane_kind}-${operation}.txt"
            extract_leaf_or_probe "flyology_simd__backends__native__${operation}${symbol_suffix}" \
              "$temporary/native.txt" \
              "saturating_arithmetic_codegen_probe__${lane_kind}_${operation}" \
              "$temporary/saturating-arithmetic-probe.txt" "$leaf"
            require_at_most '(^|[[:space:]])movdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%xmm0' 1 "$leaf" \
              "left operand transfer in ${lane_kind} ${operation} leaf"
            require_at_most '(^|[[:space:]])movdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%xmm1' 1 "$leaf" \
              "right operand transfer in ${lane_kind} ${operation} leaf"
            require_leaf_instruction '(^|[[:space:]])movdqu[[:space:]]+%xmm[0-9]+,[[:space:]]*[^,]*\([^)]*\)' 0 "$leaf" \
              "no result store in register-operand ${lane_kind} ${operation} leaf"
            if [ "$bits" -lt 32 ]; then
                if [ "$operation" = add_saturate ]; then stem=padd; else stem=psub; fi
                if [ "$signedness" = signed ]; then sign=s; else sign=us; fi
                if [ "$bits" -eq 8 ]; then width=b; else width=w; fi
                instruction="${stem}${sign}${width}"
                require_leaf_instruction "(^|[[:space:]])${instruction}[[:space:]]+%xmm[0-9]+,[[:space:]]*%xmm[0-9]+" 1 "$leaf" \
                  "exact SSE2 ${lane_kind} ${operation}"
            else
                if [ "$operation" = add_saturate ]; then arithmetic=padd; else arithmetic=psub; fi
                if [ "$bits" -eq 32 ]; then arithmetic="${arithmetic}d"; else arithmetic="${arithmetic}q"; fi
                require_leaf_instruction "(^|[[:space:]])${arithmetic}[[:space:]]+%xmm[0-9]+,[[:space:]]*%xmm[0-9]+" 1 "$leaf" \
                  "exact SSE2 ${lane_kind} ${operation} arithmetic"
                if [ "$bits" -eq 64 ]; then
                    if [ "$signedness" = signed ]; then shuffle_count=2; else shuffle_count=1; fi
                    require_count '(^|[[:space:]])pshufd[[:space:]].*\$(0x0*f5|245)([,[:space:]]|$)' \
                      "$shuffle_count" "$leaf" \
                      "64-bit lane-mask replication in ${lane_kind} ${operation}"
                fi
                if [ "$signedness" = unsigned ]; then
                    if [ "$operation" = add_saturate ]; then
                        require_leaf_instruction '(^|[[:space:]])pand[[:space:]]' 2 "$leaf" "unsigned carry masks in ${lane_kind} ${operation}"
                        require_leaf_instruction '(^|[[:space:]])por[[:space:]]' 3 "$leaf" "unsigned maximum selection in ${lane_kind} ${operation}"
                        require_leaf_instruction '(^|[[:space:]])pxor[[:space:]]' 1 "$leaf" "unsigned sum inversion in ${lane_kind} ${operation}"
                        require_leaf_instruction '(^|[[:space:]])pandn[[:space:]]' 0 "$leaf" "no subtract selection in ${lane_kind} ${operation}"
                    else
                        require_leaf_instruction '(^|[[:space:]])pand[[:space:]]' 2 "$leaf" "unsigned borrow masks in ${lane_kind} ${operation}"
                        require_leaf_instruction '(^|[[:space:]])por[[:space:]]' 1 "$leaf" "unsigned borrow merge in ${lane_kind} ${operation}"
                        require_leaf_instruction '(^|[[:space:]])pxor[[:space:]]' 3 "$leaf" "unsigned borrow transforms in ${lane_kind} ${operation}"
                        require_leaf_instruction '(^|[[:space:]])pandn[[:space:]]' 1 "$leaf" "zero-clamped selection in ${lane_kind} ${operation}"
                    fi
                    require_leaf_instruction '(^|[[:space:]])pcmpeqd[[:space:]]' 1 "$leaf" "all-ones construction in ${lane_kind} ${operation}"
                    require_leaf_instruction '(^|[[:space:]])psrad[[:space:]].*\$(0x0*1f|31)([,[:space:]]|$)' 1 "$leaf" \
                      "overflow or borrow lane expansion in ${lane_kind} ${operation}"
                else
                    if [ "$operation" = add_saturate ]; then xor_count=3; ones_count=2; else xor_count=2; ones_count=1; fi
                    require_count '(^|[[:space:]])pxor[[:space:]]' "$xor_count" "$leaf" \
                      "signed overflow transforms in ${lane_kind} ${operation}"
                    require_count '(^|[[:space:]])pcmpeqd[[:space:]]' "$ones_count" "$leaf" \
                      "signed limit construction in ${lane_kind} ${operation}"
                    require_leaf_instruction '(^|[[:space:]])pand[[:space:]]' 3 "$leaf" \
                      "signed overflow and limit masks in ${lane_kind} ${operation}"
                    require_leaf_instruction '(^|[[:space:]])pandn[[:space:]]' 2 "$leaf" \
                      "signed non-overflow selection arms in ${lane_kind} ${operation}"
                    require_leaf_instruction '(^|[[:space:]])por[[:space:]]' 2 "$leaf" \
                      "signed saturation merges in ${lane_kind} ${operation}"
                    require_leaf_instruction '(^|[[:space:]])psrad[[:space:]].*\$(0x0*1f|31)([,[:space:]]|$)' 2 "$leaf" \
                      "signed overflow and sign-mask expansion in ${lane_kind} ${operation}"
                    if [ "$bits" -eq 32 ]; then
                        require_leaf_instruction '(^|[[:space:]])pslld[[:space:]].*\$(0x0*1f|31)([,[:space:]]|$)' 1 "$leaf" \
                          "signed minimum construction in ${lane_kind} ${operation}"
                        require_leaf_instruction '(^|[[:space:]])psrld[[:space:]].*\$(0x0*1|1)([,[:space:]]|$)' 1 "$leaf" \
                          "signed maximum construction in ${lane_kind} ${operation}"
                    else
                        require_leaf_instruction '(^|[[:space:]])psllq[[:space:]].*\$(0x0*3f|63)([,[:space:]]|$)' 1 "$leaf" \
                          "signed minimum construction in ${lane_kind} ${operation}"
                        require_leaf_instruction '(^|[[:space:]])psrlq[[:space:]].*\$(0x0*1|1)([,[:space:]]|$)' 1 "$leaf" \
                          "signed maximum construction in ${lane_kind} ${operation}"
                    fi
                fi
            fi
            forbid_pattern '(^|[[:space:]])(callq?|j[a-z]+)[[:space:]]' "$leaf" \
              "branch or out-of-line helper in ${lane_kind} ${operation} leaf"
        done <scripts/probes/saturating_arithmetic_codegen_cases.txt
        while read -r lane_kind operation suffix bits lanes; do
            symbol_suffix=
            [ "$suffix" = none ] || symbol_suffix="__${suffix}"
            leaf="$temporary/lane-arrangement-leaf-${lane_kind}-${operation}.txt"
            extract_leaf_or_probe "flyology_simd__backends__native__${operation}${symbol_suffix}" \
              "$temporary/native.txt" \
              "lane_arrangement_codegen_probe__${lane_kind}_${operation}" \
              "$temporary/lane-arrangement-probe.txt" "$leaf"
            require_at_most '(^|[[:space:]])movdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%xmm0' 1 "$leaf" \
              "left operand transfer in ${lane_kind} ${operation} leaf"
            if [ "$operation" != reverse_lanes ]; then
                require_at_most '(^|[[:space:]])movdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%xmm1' 1 "$leaf" \
                  "right operand transfer in ${lane_kind} ${operation} leaf"
            fi
            require_leaf_instruction '(^|[[:space:]])movdqu[[:space:]]+%xmm[0-9]+,[[:space:]]*[^,]*\([^)]*\)' 0 "$leaf" \
              "no result store in register-operand ${lane_kind} ${operation} leaf"
            case "$operation:$bits" in
                interleave_low:8) instruction=punpcklbw ;; interleave_high:8) instruction=punpckhbw ;;
                interleave_low:16) instruction=punpcklwd ;; interleave_high:16) instruction=punpckhwd ;;
                interleave_low:32) if [ "$lane_kind" = f32 ]; then instruction=unpcklps; else instruction=punpckldq; fi ;;
                interleave_high:32) if [ "$lane_kind" = f32 ]; then instruction=unpckhps; else instruction=punpckhdq; fi ;;
                interleave_low:64) if [ "$lane_kind" = f64 ]; then instruction=unpcklpd; else instruction=punpcklqdq; fi ;;
                interleave_high:64) if [ "$lane_kind" = f64 ]; then instruction=unpckhpd; else instruction=punpckhqdq; fi ;;
                deinterleave_even:64) instruction=punpcklqdq ;; deinterleave_odd:64) instruction=punpckhqdq ;;
                *) instruction= ;;
            esac
            [ -z "$instruction" ] || require_leaf_instruction "(^|[[:space:]])${instruction}[[:space:]]" 1 "$leaf" "exact SSE2 ${lane_kind} ${operation} leaf"
            case "$operation:$bits" in
                reverse_lanes:8)
                    require_leaf_instruction '(^|[[:space:]])psrlw[[:space:]].*\$(0x0*8|8)' 1 "$leaf" "byte reversal right shift"
                    require_leaf_instruction '(^|[[:space:]])psllw[[:space:]].*\$(0x0*8|8)' 1 "$leaf" "byte reversal left shift"
                    require_leaf_instruction '(^|[[:space:]])por[[:space:]]' 1 "$leaf" "byte reversal merge"
                    require_leaf_instruction '(^|[[:space:]])pshuflw[[:space:]].*\$(0x0*1[bB]|27)' 1 "$leaf" "low-word reversal"
                    require_leaf_instruction '(^|[[:space:]])pshufhw[[:space:]].*\$(0x0*1[bB]|27)' 1 "$leaf" "high-word reversal"
                    require_leaf_instruction '(^|[[:space:]])pshufd[[:space:]].*\$(0x0*4[eE]|78)' 1 "$leaf" "half reversal"
                    ;;
                reverse_lanes:16)
                    require_leaf_instruction '(^|[[:space:]])pshuflw[[:space:]].*\$(0x0*1[bB]|27)' 1 "$leaf" "low-word reversal"
                    require_leaf_instruction '(^|[[:space:]])pshufhw[[:space:]].*\$(0x0*1[bB]|27)' 1 "$leaf" "high-word reversal"
                    require_leaf_instruction '(^|[[:space:]])pshufd[[:space:]].*\$(0x0*4[eE]|78)' 1 "$leaf" "half reversal"
                    ;;
                reverse_lanes:32) require_leaf_instruction '(^|[[:space:]])pshufd[[:space:]].*\$(0x0*1[bB]|27)' 1 "$leaf" "dword reversal" ;;
                reverse_lanes:64) require_leaf_instruction '(^|[[:space:]])pshufd[[:space:]].*\$(0x0*4[eE]|78)' 1 "$leaf" "qword reversal" ;;
                deinterleave_even:8)
                    require_leaf_instruction '(^|[[:space:]])pcmpeqd[[:space:]]' 1 "$leaf" "even-byte all-ones mask construction"
                    require_leaf_instruction '(^|[[:space:]])psrlw[[:space:]].*\$(0x0*8|8)' 1 "$leaf" "even-byte low mask derivation"
                    require_leaf_instruction '(^|[[:space:]])pand[[:space:]]' 2 "$leaf" "two even-byte masks"
                    require_leaf_instruction '(^|[[:space:]])packuswb[[:space:]]' 1 "$leaf" "even-byte packing"
                    ;;
                deinterleave_odd:8)
                    require_leaf_instruction '(^|[[:space:]])psrlw[[:space:]].*\$(0x0*8|8)' 2 "$leaf" "two odd-byte shifts"
                    require_leaf_instruction '(^|[[:space:]])packuswb[[:space:]]' 1 "$leaf" "odd-byte packing"
                    ;;
                deinterleave_even:16)
                    require_leaf_instruction '(^|[[:space:]])pshuflw[[:space:]].*\$(0x0*88|136)' 2 "$leaf" "two even low-word selections"
                    require_leaf_instruction '(^|[[:space:]])pshufhw[[:space:]].*\$(0x0*88|136)' 2 "$leaf" "two even high-word selections"
                    require_leaf_instruction '(^|[[:space:]])pshufd[[:space:]].*\$(0x0*88|136)' 2 "$leaf" "two half packings"
                    require_leaf_instruction '(^|[[:space:]])punpcklqdq[[:space:]]' 1 "$leaf" "word result merge"
                    ;;
                deinterleave_odd:16)
                    require_leaf_instruction '(^|[[:space:]])pshuflw[[:space:]].*\$(0x0*[dD][dD]|221)' 2 "$leaf" "two odd low-word selections"
                    require_leaf_instruction '(^|[[:space:]])pshufhw[[:space:]].*\$(0x0*[dD][dD]|221)' 2 "$leaf" "two odd high-word selections"
                    require_leaf_instruction '(^|[[:space:]])pshufd[[:space:]].*\$(0x0*88|136)' 2 "$leaf" "two half packings"
                    require_leaf_instruction '(^|[[:space:]])punpcklqdq[[:space:]]' 1 "$leaf" "word result merge"
                    ;;
                deinterleave_even:32)
                    require_leaf_instruction '(^|[[:space:]])pshufd[[:space:]].*\$(0x0*88|136)' 2 "$leaf" "two even-dword selections"
                    require_leaf_instruction '(^|[[:space:]])punpcklqdq[[:space:]]' 1 "$leaf" "dword result merge"
                    ;;
                deinterleave_odd:32)
                    require_leaf_instruction '(^|[[:space:]])pshufd[[:space:]].*\$(0x0*[dD][dD]|221)' 2 "$leaf" "two odd-dword selections"
                    require_leaf_instruction '(^|[[:space:]])punpcklqdq[[:space:]]' 1 "$leaf" "dword result merge"
                    ;;
            esac
            forbid_pattern '(^|[[:space:]])(callq?|jmpq?)[[:space:]]' "$leaf" \
              "branch or out-of-line helper in ${lane_kind} ${operation} leaf"
        done <scripts/probes/lane_arrangement_codegen_cases.txt
        while read -r lane_kind operation suffix; do
            if [ "$lane_kind" = u8 ] && [ "$operation" = load_unaligned ]; then
                continue
            fi
            symbol_suffix=
            [ "$suffix" = none ] || symbol_suffix="__${suffix}"
            leaf="$temporary/complete-memory-leaf-${lane_kind}-${operation}.txt"
            extract_leaf_or_probe "flyology_simd__backends__native__${operation}${symbol_suffix}" \
              "$temporary/native.txt" \
              "complete_memory_codegen_probe__${lane_kind}_${operation}" \
              "$temporary/complete-memory-probe.txt" "$leaf"
            #  The byte family's memory leaves now move between the array and a
            #  register directly; the other families still stage the value in a
            #  private buffer, so each is asserted against what it actually does.
            case "$operation" in
                load_aligned)
                    require_leaf_instruction '(^|[[:space:]])movdqa[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%xmm[0-9]+' 1 "$leaf" \
                      "x86 ${lane_kind} aligned array load into a register"
                    ;;
                store_aligned)
                    require_leaf_instruction '(^|[[:space:]])movdqa[[:space:]]+%xmm[0-9]+,[[:space:]]*[^,]*\([^)]*\)' 1 "$leaf" \
                      "x86 ${lane_kind} aligned array store from a register"
                    ;;
                load|load_unaligned)
                    require_leaf_instruction '(^|[[:space:]])movdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%xmm[0-9]+' 1 "$leaf" \
                      "x86 ${lane_kind} ${operation} unaligned-safe array load"
                    forbid_pattern '(^|[[:space:]])movdqa[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%xmm[0-9]+' "$leaf" \
                      "unexpected aligned array load in x86 ${lane_kind} ${operation} leaf"
                    ;;
                *)
                    require_leaf_instruction '(^|[[:space:]])movdqu[[:space:]]+%xmm[0-9]+,[[:space:]]*[^,]*\([^)]*\)' 1 "$leaf" \
                      "x86 ${lane_kind} ${operation} unaligned-safe array store"
                    forbid_pattern '(^|[[:space:]])movdqa[[:space:]]+%xmm[0-9]+,[[:space:]]*[^,]*\([^)]*\)' "$leaf" \
                      "unexpected aligned array store in x86 ${lane_kind} ${operation} leaf"
                    ;;
            esac
            forbid_pattern 'flyology_simd__(backends__scalar__|wide__)?(load|store)(_unaligned|_aligned)?' \
              "$leaf" "portable, Scalar, or Wide helper in x86 ${lane_kind} ${operation} leaf"
        done <scripts/probes/complete_memory_codegen_cases.txt
        while read -r lane_kind operation suffix shape x86_shape; do
            symbol_suffix=
            [ "$suffix" = none ] || symbol_suffix="__${suffix}"
            leaf="$temporary/float-binary-leaf-${lane_kind}-${operation}.txt"
            case "$operation" in
                add|subtract|multiply|divide)
                    extract_leaf_or_probe "flyology_simd__backends__native__${operation}${symbol_suffix}" \
                      "$temporary/native.txt" \
                      "float_binary_codegen_probe__${lane_kind}_${operation}" \
                      "$temporary/float-binary-probe.txt" "$leaf"
                    case "$operation" in
                        add) instruction="add${x86_shape}" ;;
                        subtract) instruction="sub${x86_shape}" ;;
                        multiply) instruction="mul${x86_shape}" ;;
                        divide) instruction="div${x86_shape}" ;;
                    esac
                    ;;
                min_number|max_number)
                    case "$lane_kind" in f32) lanes=4 ;; f64) lanes=2 ;; esac
                    extract_symbol "flyology_simd__backends__native__native_${operation}_${lane_kind}x${lanes}" \
                      "$temporary/native.txt" "$leaf"
                    instruction=pcmpgtd
                    ;;
            esac
            if [ "$operation" = min_number ] || [ "$operation" = max_number ]; then
                if [ "$lane_kind" = f32 ]; then
                    require_leaf_instruction '(^|[[:space:]])pcmpgtd[[:space:]]' 5 "$leaf" "exact SSE2 ordering in ${lane_kind} ${operation} leaf"
                    require_leaf_instruction '(^|[[:space:]])pcmpeqd[[:space:]]' 10 "$leaf" "exact SSE2 classification in ${lane_kind} ${operation} leaf"
                    require_leaf_instruction '(^|[[:space:]])pand[[:space:]]' 11 "$leaf" "exact SSE2 masks in ${lane_kind} ${operation} leaf"
                    require_leaf_instruction '(^|[[:space:]])pandn[[:space:]]' 7 "$leaf" "exact SSE2 masked selections in ${lane_kind} ${operation} leaf"
                    require_leaf_instruction '(^|[[:space:]])por[[:space:]]' 7 "$leaf" "exact SSE2 merges in ${lane_kind} ${operation} leaf"
                    require_leaf_instruction '(^|[[:space:]])pxor[[:space:]]' 2 "$leaf" "exact SSE2 keys in ${lane_kind} ${operation} leaf"
                else
                    require_leaf_instruction '(^|[[:space:]])pcmpgtd[[:space:]]' 10 "$leaf" "exact SSE2 ordering in ${lane_kind} ${operation} leaf"
                    require_leaf_instruction '(^|[[:space:]])pcmpeqd[[:space:]]' 20 "$leaf" "exact SSE2 classification in ${lane_kind} ${operation} leaf"
                    require_leaf_instruction '(^|[[:space:]])pand[[:space:]]' 16 "$leaf" "exact SSE2 masks in ${lane_kind} ${operation} leaf"
                    require_leaf_instruction '(^|[[:space:]])pandn[[:space:]]' 7 "$leaf" "exact SSE2 masked selections in ${lane_kind} ${operation} leaf"
                    require_leaf_instruction '(^|[[:space:]])por[[:space:]]' 12 "$leaf" "exact SSE2 merges in ${lane_kind} ${operation} leaf"
                    require_leaf_instruction '(^|[[:space:]])pxor[[:space:]]' 12 "$leaf" "exact SSE2 keys in ${lane_kind} ${operation} leaf"
                    require_leaf_instruction '(^|[[:space:]])pshufd[[:space:]]' 21 "$leaf" "exact SSE2 64-bit mask replication in ${lane_kind} ${operation} leaf"
                fi
            else
                require_leaf_instruction "(^|[[:space:]])${instruction}[[:space:]]" 1 "$leaf" \
                  "exact SSE2 ${lane_kind} ${operation} leaf"
            fi
            forbid_pattern '(^|[[:space:]])(callq?|jmpq?)[[:space:]]' \
              "$leaf" "branch or out-of-line helper in ${lane_kind} ${operation} leaf"
        done <scripts/probes/float_binary_codegen_cases.txt
        extract_symbol 'construction_codegen_probe__splat_u8' \
          "$temporary/construction-probe.txt" "$temporary/construction-splat-u8.txt"
        #  The byte splat fills a general register and moves it across, the
        #  same broadcast every other integer family uses.
        require_pattern 'imul[a-z]*[[:space:]]+\$0x1010101' \
          "$temporary/construction-splat-u8.txt" \
          'inlined x86-64 byte broadcast in the U8x16 public caller probe'
        require_pattern 'pshufd' "$temporary/construction-splat-u8.txt" \
          'inlined x86-64 dword broadcast in the U8x16 public caller probe'
        forbid_pattern '(^|[[:space:]])(call|jmp)[[:space:]]|flyology_simd__(backends__native__)?splat' \
          "$temporary/construction-splat-u8.txt" \
          'out-of-line U8x16 broadcast in the x86-64 public caller probe'
        extract_symbol 'flyology_simd__backends__native__zero' \
          "$temporary/native.txt" "$temporary/construction-zero-u8.txt"
        require_pattern 'xor(l)?[[:space:]]+%e(ax|dx)' \
          "$temporary/construction-zero-u8.txt" \
          'direct x86-64 U8x16 zero result construction'
        #  Zero and Splat inline into whoever asks for them, so the
        #  construction is inspected in the probe rather than in a leaf.
        for kind in i8 u16 i16 u32 i32 u64 i64 f32 f64; do
            extract_symbol "construction_codegen_probe__zero_${kind}" \
              "$temporary/construction-probe.txt" \
              "$temporary/construction-zero-${kind}.txt"
            require_pattern 'pxor|xor(l|q)?[[:space:]]' \
              "$temporary/construction-zero-${kind}.txt" \
              "x86-64 SSE2 zero construction for ${kind}"
        done
        for kind in i8 u16 i16 u32 i32; do
            extract_symbol "construction_codegen_probe__splat_${kind}" \
              "$temporary/construction-probe.txt" \
              "$temporary/construction-splat-${kind}.txt"
            require_pattern 'pshufd' "$temporary/construction-splat-${kind}.txt" \
              "x86-64 SSE2 8/16/32-bit broadcast for ${kind}"
        done
        for kind in u64 i64 f64; do
            extract_symbol "construction_codegen_probe__splat_${kind}" \
              "$temporary/construction-probe.txt" \
              "$temporary/construction-splat-${kind}.txt"
            require_pattern 'punpcklqdq|unpcklpd' \
              "$temporary/construction-splat-${kind}.txt" \
              "x86-64 SSE2 64-bit broadcast for ${kind}"
        done
        extract_symbol 'construction_codegen_probe__splat_f32' \
          "$temporary/construction-probe.txt" "$temporary/construction-splat-f32.txt"
        require_pattern 'shufps|pshufd' "$temporary/construction-splat-f32.txt" \
          'x86-64 SSE2 single-precision broadcast'

        extract_symbol 'flyology_simd__backends__native__horizontal_sum' \
          "$temporary/native.txt" "$temporary/horizontal-sum-u8x16.txt"
        require_pattern '(^|[[:space:]])psadbw[[:space:]]' \
          "$temporary/horizontal-sum-u8x16.txt" \
          'x86-64 U8x16 pairwise byte sums'
        require_pattern '(^|[[:space:]])movhlps[[:space:]]' \
          "$temporary/horizontal-sum-u8x16.txt" \
          'x86-64 U8x16 high partial-sum transfer'
        require_pattern '(^|[[:space:]])paddq[[:space:]]' \
          "$temporary/horizontal-sum-u8x16.txt" \
          'x86-64 U8x16 partial-sum addition'
        forbid_pattern 'flyology_simd__horizontal_sum' \
          "$temporary/horizontal-sum-u8x16.txt" \
          'portable x86-64 Horizontal_Sum call'
        for suffix in '' '__2' '__3' '__4'; do
            extract_symbol "flyology_simd__backends__native__population_count${suffix}" \
              "$temporary/native.txt" "$temporary/population_count${suffix}.txt"
            extract_symbol "flyology_simd__backends__native__first_true${suffix}" \
              "$temporary/native.txt" "$temporary/first_true${suffix}.txt"
            extract_symbol "flyology_simd__backends__native__last_true${suffix}" \
              "$temporary/native.txt" "$temporary/last_true${suffix}.txt"
            require_pattern '(^|[[:space:]])bsf(l)?([[:space:]]|$)' \
              "$temporary/first_true${suffix}.txt" \
              'x86-64 First_True bit scan'
            require_pattern '(^|[[:space:]])bsr(l)?([[:space:]]|$)' \
              "$temporary/last_true${suffix}.txt" \
              'x86-64 Last_True bit scan'
            require_pattern '0x55555555' "$temporary/population_count${suffix}.txt" \
              'x86-64 Population_Count pairwise arithmetic mask'
            require_pattern '0x33333333' "$temporary/population_count${suffix}.txt" \
              'x86-64 Population_Count nibble arithmetic mask'
            require_pattern '0x1010101' "$temporary/population_count${suffix}.txt" \
              'x86-64 Population_Count byte sum multiplier'
            forbid_pattern '(^|[[:space:]])popcnt' \
              "$temporary/population_count${suffix}.txt" \
              'x86-64 Population_Count unexpectedly requires POPCNT'
            forbid_pattern 'flyology_simd__first_true|flyology_simd__last_true' \
              "$temporary/first_true${suffix}.txt" \
              'portable x86-64 mask-position call'
            forbid_pattern 'flyology_simd__first_true|flyology_simd__last_true' \
              "$temporary/last_true${suffix}.txt" \
              'portable x86-64 mask-position call'
            forbid_pattern 'flyology_simd__population_count' \
              "$temporary/population_count${suffix}.txt" \
              'portable x86-64 population-count call'
        done
        extract_symbol 'native_reduce_add_f32x4' "$temporary/native.txt" \
          "$temporary/reduce-add-f32x4.txt"
        extract_symbol 'native_reduce_add_f64x2' "$temporary/native.txt" \
          "$temporary/reduce-add-f64x2.txt"
        require_count 'addss' 4 "$temporary/reduce-add-f32x4.txt" \
          'four ascending scalar SSE2 additions in F32x4 Reduce_Add'
        require_count 'addsd' 2 "$temporary/reduce-add-f64x2.txt" \
          'two ascending scalar SSE2 additions in F64x2 Reduce_Add'
        for reduction in reduce-add-f32x4 reduce-add-f64x2; do
            #  Whichever register the allocator picks, the accumulator starts
            #  at positive zero by being exclusive-ored with itself.
            require_pattern 'pxor[[:space:]]+%xmm([0-9]+),[[:space:]]*%xmm\1' \
              "$temporary/${reduction}.txt" \
              "positive-zero accumulator in ${reduction}"
            forbid_pattern '(^|[[:space:]])call[[:space:]]|flyology_simd__reduce_add' \
              "$temporary/${reduction}.txt" \
              "out-of-line or portable reduction in ${reduction}"
        done
        while read -r symbol output kind steps; do
            section=$output
            output="$temporary/$section.txt"
            extract_symbol "$symbol" "$temporary/native.txt" "$output"
            require_pattern '(^|[[:space:]])pcmpgtd[[:space:]]' \
              "$output" \
              "integer SSE2 ordering in $section"
            require_pattern '(^|[[:space:]])pcmpeqd[[:space:]]' \
              "$output" \
              "integer SSE2 NaN classification in $section"
            require_pattern '(^|[[:space:]])pandn[[:space:]]' \
              "$output" \
              "SSE2 masked selection in $section"
            require_pattern '(^|[[:space:]])por[[:space:]]' \
              "$output" \
              "SSE2 selected-value merge in $section"
            require_pattern '(^|[[:space:]])pxor[[:space:]]' \
              "$output" \
              "SSE2 sortable-key or quiet-bit construction in $section"
            require_pattern '(^|[[:space:]])ps(ra|rl|ll)(d|q)[[:space:]]' \
              "$output" \
              "SSE2 classification and sortable-key shifts in $section"
            forbid_pattern '(^|[[:space:]])call[[:space:]]|flyology_simd__(min_number|max_number|reduce_min_number|reduce_max_number)' \
              "$output" \
              "portable or out-of-line helper in $section"
            forbid_pattern '(^|[[:space:]])(min|max)(ps|pd|ss|sd)[[:space:]]|(^|[[:space:]])cmp(unord|lt|le|eq)(ps|pd|ss|sd)[[:space:]]' \
              "$output" \
              "floating comparison or bare min/max in $section"
            if [ "$kind" = f64 ]; then
                require_pattern '(^|[[:space:]])pshufd[[:space:]]' \
                  "$output" \
                  "64-bit dword-mask replication in $section"
            fi
            if [ "$steps" -gt 0 ]; then
                require_count '(^|[[:space:]])psrldq[[:space:]]' "$steps" \
                  "$output" \
                  "ascending lane advances in $section"
            fi
        done <<'EOF'
native_min_number_f32x4          min-number-f32x4          f32 0
native_max_number_f32x4          max-number-f32x4          f32 0
native_min_number_f64x2          min-number-f64x2          f64 0
native_max_number_f64x2          max-number-f64x2          f64 0
native_reduce_min_number_f32x4   reduce-min-number-f32x4   f32 3
native_reduce_max_number_f32x4   reduce-max-number-f32x4   f32 3
native_reduce_min_number_f64x2   reduce-min-number-f64x2   f64 1
native_reduce_max_number_f64x2   reduce-max-number-f64x2   f64 1
EOF
        while read -r symbol output_name; do
            extract_symbol "$symbol" \
              "$temporary/wide-float-reduction-leaf.txt" \
              "$temporary/$output_name.txt"
            forbid_pattern '(^|[[:space:]])(call|jmp)[[:space:]]|flyology_simd__wide__reduce_' \
              "$temporary/$output_name.txt" \
              "portable or out-of-line helper in $output_name"
        done <<'EOF'
flyology_simd__wide__float_reduce_selected_leaf__reduce_add              wide-f32-reduce-add-leaf
flyology_simd__wide__float_reduce_selected_leaf__reduce_min_number       wide-f32-reduce-min_number-leaf
flyology_simd__wide__float_reduce_selected_leaf__reduce_max_number       wide-f32-reduce-max_number-leaf
flyology_simd__wide__float_reduce_selected_leaf__reduce_add__2           wide-f64-reduce-add-leaf
flyology_simd__wide__float_reduce_selected_leaf__reduce_min_number__2    wide-f64-reduce-min_number-leaf
flyology_simd__wide__float_reduce_selected_leaf__reduce_max_number__2    wide-f64-reduce-max_number-leaf
EOF
        require_count '(^|[[:space:]])addss[[:space:]]' 8 \
          "$temporary/wide-f32-reduce-add-leaf.txt" \
          'eight ordered SSE2 binary32 additions in Wide Reduce_Add'
        require_count '(^|[[:space:]])addsd[[:space:]]' 4 \
          "$temporary/wide-f64-reduce-add-leaf.txt" \
          'four ordered SSE2 binary64 additions in Wide Reduce_Add'
        require_count '(^|[[:space:]])pxor[[:space:]].*xmm0.*xmm0' 1 \
          "$temporary/wide-f32-reduce-add-leaf.txt" \
          'positive-zero binary32 accumulator in Wide Reduce_Add'
        require_count '(^|[[:space:]])pxor[[:space:]].*xmm0.*xmm0' 1 \
          "$temporary/wide-f64-reduce-add-leaf.txt" \
          'positive-zero binary64 accumulator in Wide Reduce_Add'
        while read -r kind operation steps ordering classes masked_selects merges; do
            leaf="$temporary/wide-${kind}-reduce-${operation}-leaf.txt"
            require_count '(^|[[:space:]])pcmpgtd[[:space:]]' "$ordering" "$leaf" \
              "integer SSE2 ordering for every step in Wide ${kind} ${operation}"
            require_count '(^|[[:space:]])pcmpeqd[[:space:]]' "$classes" "$leaf" \
              "integer SSE2 NaN classification for every step in Wide ${kind} ${operation}"
            require_count '(^|[[:space:]])pandn[[:space:]]' "$masked_selects" "$leaf" \
              "SSE2 masked selection for every step in Wide ${kind} ${operation}"
            require_count '(^|[[:space:]])por[[:space:]]' "$merges" "$leaf" \
              "SSE2 selected-value merge for every step in Wide ${kind} ${operation}"
            forbid_pattern '(^|[[:space:]])(min|max)(ps|pd|ss|sd)[[:space:]]|(^|[[:space:]])cmp(unord|lt|le|eq)(ps|pd|ss|sd)[[:space:]]' \
              "$leaf" "floating compare or bare min/max in Wide ${kind} ${operation}"
        done <<'EOF'
f32 min_number 7 35 70 49 49
f32 max_number 7 35 70 49 49
f64 min_number 3 30 60 21 36
f64 max_number 3 30 60 21 36
EOF
        while read -r symbol description; do
            require_count "$symbol" 1 \
              "$temporary/wide-float-reduction-undefined.txt" \
              "one selected x86 floating-reduction leaf call for $description"
        done <<'EOF'
flyology_simd__wide__float_reduce_selected_leaf__reduce_add$             F32-Reduce_Add
flyology_simd__wide__float_reduce_selected_leaf__reduce_min_number$      F32-Reduce_Min_Number
flyology_simd__wide__float_reduce_selected_leaf__reduce_max_number$      F32-Reduce_Max_Number
flyology_simd__wide__float_reduce_selected_leaf__reduce_add__2$          F64-Reduce_Add
flyology_simd__wide__float_reduce_selected_leaf__reduce_min_number__2$   F64-Reduce_Min_Number
flyology_simd__wide__float_reduce_selected_leaf__reduce_max_number__2$   F64-Reduce_Max_Number
EOF
        forbid_pattern 'flyology_simd__wide__reduce_|flyology_simd__wide__native__reduce_' \
          "$temporary/wide-float-reduction-undefined.txt" \
          'portable or public Native Wide floating reduction retained on x86-64'
        forbid_pattern 'flyology_simd__wide__reduce_|flyology_simd__wide__native__reduce_' \
          "$temporary/wide-float-reduction-leaf-undefined.txt" \
          'portable or public Native call retained in the x86 floating-reduction leaf'
        forbid_pattern 'flyology_simd__wide__reduce_' \
          "$temporary/wide-float-reduction-undefined.txt" \
          'portable Wide floating reduction retained on x86-64'
        forbid_pattern 'flyology_simd__wide__native__reduce_' \
          "$temporary/wide-float-reduction-probe.txt" \
          'Wide.Native floating-reduction dispatcher retained on x86-64'
        : >"$temporary/baseline.txt"
        for object in "$object_root"/*.o; do
            case "$object" in
                *flyology_simd-algorithms-avx2_implementation.o) continue ;;
                *flyology_simd-wide-lookup_mechanism.o)
                    if [ "$wide_backend" = avx2 ]; then
                        continue
                    fi
                    ;;
                *flyology_simd-wide-byte_avx2_leaf.o)
                    if [ "$wide_backend" = avx2 ]; then
                        continue
                    fi
                    ;;
                *flyology_simd-wide-float_avx2_leaf.o)
                    if [ "$wide_backend" = avx2 ]; then
                        continue
                    fi
                    ;;
                *flyology_simd-wide-permute_mechanism.o)
                    if [ "$wide_backend" = avx2 ]; then
                        continue
                    fi
                    ;;
            esac
            disassemble "$object" >>"$temporary/baseline.txt"
        done
        require_pattern 'pcmpeqb' "$(native_and_probes)" 'SSE2 byte comparison'
        require_pattern 'pcmpeqw' "$(native_and_probes)" 'SSE2 16-bit comparison'
        require_pattern 'pcmpeqd' "$(native_and_probes)" 'SSE2 32/64-bit comparison composition'
        require_pattern 'pmovmskb' "$(native_and_probes)" 'SSE2 compact mask extraction'
        require_pattern 'paddb' "$(native_and_probes)" 'SSE2 wrapping byte add'
        require_pattern 'paddw' "$(native_and_probes)" 'SSE2 wrapping 16-bit add'
        require_pattern 'paddd' "$(native_and_probes)" 'SSE2 wrapping 32-bit add'
        require_pattern 'paddq' "$(native_and_probes)" 'SSE2 wrapping 64-bit add'
        while read -r operation instruction_pattern matching_symbols; do
            bind_u8_selected_operation \
              "$temporary/u8-value-${operation}.txt" \
              "$instruction_pattern" "$matching_symbols" \
              "$temporary/native.txt" \
              "$temporary/u8-native-${operation}.txt" \
              "x86-64 U8 ${operation} caller"
            require_exact_u8_operation \
              "$temporary/u8-value-${operation}.txt" \
              "$temporary/u8-native-${operation}.txt" \
              "$instruction_pattern" "$operation" \
              "x86-64 U8 ${operation}"
        done <<'EOF'
add_wrap paddb add_wrap|u8_add_wrap
subtract_wrap psubb subtract_wrap|u8_subtract_wrap
multiply_wrap pmullw multiply_wrap|native_multiply_wrap_u8x16
add_saturate paddusb add_saturate|u8_add_saturate
subtract_saturate psubusb subtract_saturate|u8_subtract_saturate
bitwise_and pand bitwise_and|u8_and
bitwise_or por bitwise_or|u8_or
bitwise_xor pxor bitwise_xor|u8_xor
bitwise_not pcmpeqd bitwise_not|u8_not
equal pcmpeqb equal|equal_mask
less_than pcmpgtb less_than|greater_mask
less_equal pcmpgtb less_equal|greater_mask
greater_than pcmpgtb greater_than|greater_mask
greater_equal pcmpgtb greater_equal|greater_mask
select_value pandn select_value
min pminub min
max pmaxub max
reduce_add_wrap paddb reduce_add_wrap|native_reduce_add_wrap_u8x16
reduce_min pminub reduce_min|native_reduce_min_u8x16
reduce_max pmaxub reduce_max|native_reduce_max_u8x16
reverse_bytes pshufd reverse_bytes|u8_reverse
reverse_lanes pshufd reverse_lanes|u8_reverse
interleave_low punpcklbw interleave_low|u8_interleave_low
interleave_high punpckhbw interleave_high|u8_interleave_high
deinterleave_even packuswb deinterleave_even|u8_deinterleave_even
deinterleave_odd packuswb deinterleave_odd|u8_deinterleave_odd
EOF
        require_count '(^|[[:space:]])pmullw[[:space:]]' 2 \
          "$temporary/u8-native-multiply_wrap.txt" \
          'two widened products in x86-64 U8 Multiply_Wrap'
        require_count '(^|[[:space:]])pand[[:space:]]' 2 \
          "$temporary/u8-native-multiply_wrap.txt" \
          'two low-byte masks in x86-64 U8 Multiply_Wrap'
        require_pattern '(^|[[:space:]])packuswb[[:space:]]' \
          "$temporary/u8-native-multiply_wrap.txt" \
          'byte repacking in x86-64 U8 Multiply_Wrap'
        for operation in equal less_than less_equal greater_than greater_equal; do
            require_pattern '(^|[[:space:]])pmovmskb[[:space:]]' \
              "$temporary/u8-native-${operation}.txt" \
              "compact mask extraction in x86-64 U8 ${operation}"
        done
        for operation in less_than less_equal greater_than greater_equal; do
            require_pattern '(^|[[:space:]])pcmpgtb[[:space:]]' \
              "$temporary/u8-native-${operation}.txt" \
              "unsigned ordering comparison in x86-64 U8 ${operation}"
        done
        require_pattern '(^|[[:space:]])punpcklbw[[:space:]]' \
          "$temporary/u8-native-select_value.txt" \
          'byte mask expansion in x86-64 U8 Select_Value'
        require_pattern '(^|[[:space:]])punpcklwd[[:space:]]' \
          "$temporary/u8-native-select_value.txt" \
          'word mask expansion in x86-64 U8 Select_Value'
        require_pattern '(^|[[:space:]])punpckldq[[:space:]]' \
          "$temporary/u8-native-select_value.txt" \
          'dword mask expansion in x86-64 U8 Select_Value'
        require_pattern '(^|[[:space:]])pandn[[:space:]]' \
          "$temporary/u8-native-select_value.txt" \
          'false-lane masking in x86-64 U8 Select_Value'
        require_pattern '(^|[[:space:]])por[[:space:]]' \
          "$temporary/u8-native-select_value.txt" \
          'selected-lane merge in x86-64 U8 Select_Value'
        for operation in reverse_bytes reverse_lanes; do
            require_pattern '(^|[[:space:]])psrlw[[:space:]]' \
              "$temporary/u8-native-${operation}.txt" \
              "right byte shift in x86-64 U8 ${operation}"
            require_pattern '(^|[[:space:]])psllw[[:space:]]' \
              "$temporary/u8-native-${operation}.txt" \
              "left byte shift in x86-64 U8 ${operation}"
            require_pattern '(^|[[:space:]])pshufd[[:space:]]' \
              "$temporary/u8-native-${operation}.txt" \
              "dword reversal in x86-64 U8 ${operation}"
        done
        require_count '(^|[[:space:]])pand[[:space:]]' 2 \
          "$temporary/u8-native-deinterleave_even.txt" \
          'two even-byte masks in x86-64 U8 Deinterleave_Even'
        require_count '(^|[[:space:]])psrlw[[:space:]]' 2 \
          "$temporary/u8-native-deinterleave_odd.txt" \
          'two odd-byte shifts in x86-64 U8 Deinterleave_Odd'
        #  Inspect every public integer-reduction overload.  Aggregate object
        #  searches can pass when an unrelated operation contains the same
        #  instruction, so each reduction must retain its complete packed
        #  tree and must not call the portable scalar authority.
        while read -r lane_kind suffix add_instruction stages extreme_kind; do
            [ -n "$lane_kind" ] || continue
            if [ "$suffix" = none ]; then
                suffix=
            fi
            for operation in reduce_add_wrap reduce_min reduce_max; do
                symbol="flyology_simd__backends__native__${operation}${suffix}"
                output="$temporary/reduction_${lane_kind}_${operation}.txt"
                extract_symbol "$symbol" "$temporary/native.txt" "$output"
                forbid_pattern '(^|[[:space:]])(callq?|jmpq?)[[:space:]]|flyology_simd__reduce_' \
                  "$output" \
                  "portable or out-of-line helper in ${lane_kind} ${operation}"
            done
            require_count "(^|[[:space:]])${add_instruction}[[:space:]]" "$stages" \
              "$temporary/reduction_${lane_kind}_reduce_add_wrap.txt" \
              "complete SSE2 ${lane_kind} wrapping-add reduction tree"
            case "$extreme_kind" in
                byte_unsigned)
                    require_count '(^|[[:space:]])pminub[[:space:]]' "$stages" \
                      "$temporary/reduction_${lane_kind}_reduce_min.txt" \
                      "complete SSE2 ${lane_kind} minimum reduction tree"
                    require_count '(^|[[:space:]])pmaxub[[:space:]]' "$stages" \
                      "$temporary/reduction_${lane_kind}_reduce_max.txt" \
                      "complete SSE2 ${lane_kind} maximum reduction tree"
                    ;;
                word_signed)
                    require_count '(^|[[:space:]])pminsw[[:space:]]' "$stages" \
                      "$temporary/reduction_${lane_kind}_reduce_min.txt" \
                      "complete SSE2 ${lane_kind} minimum reduction tree"
                    require_count '(^|[[:space:]])pmaxsw[[:space:]]' "$stages" \
                      "$temporary/reduction_${lane_kind}_reduce_max.txt" \
                      "complete SSE2 ${lane_kind} maximum reduction tree"
                    ;;
                compare_select)
                    for operation in reduce_min reduce_max; do
                        require_pattern '(^|[[:space:]])pcmpgt(b|w|d)[[:space:]]' \
                          "$temporary/reduction_${lane_kind}_${operation}.txt" \
                          "SSE2 comparison in ${lane_kind} ${operation} reduction"
                        require_count '(^|[[:space:]])pandn[[:space:]]' "$stages" \
                          "$temporary/reduction_${lane_kind}_${operation}.txt" \
                          "complete SSE2 ${lane_kind} ${operation} selection tree"
                        if [ "$lane_kind" != u64 ] && [ "$lane_kind" != i64 ]; then
                            require_count '(^|[[:space:]])pand[[:space:]]' "$stages" \
                              "$temporary/reduction_${lane_kind}_${operation}.txt" \
                              "complete SSE2 ${lane_kind} ${operation} true-value selection tree"
                            merge_count=$stages
                            if [ "$lane_kind" = i8 ]; then
                                merge_count=$((stages + 2))
                            fi
                            require_count '(^|[[:space:]])por[[:space:]]' "$merge_count" \
                              "$temporary/reduction_${lane_kind}_${operation}.txt" \
                              "complete SSE2 ${lane_kind} ${operation} shuffle and selected-value merge tree"
                        fi
                    done
                    ;;
            esac
            case "$lane_kind" in
                u8|i8|u32|i32)
                    for operation in reduce_add_wrap reduce_min reduce_max; do
                        require_pattern '(^|[[:space:]])movd[[:space:]]' \
                          "$temporary/reduction_${lane_kind}_${operation}.txt" \
                          "SSE2 ${lane_kind} ${operation} result extraction"
                        if [ "$lane_kind" = u8 ] || [ "$lane_kind" = i8 ]; then
                            #  The byte result leaves in a register now rather
                            #  than being stored through a private buffer.
                            require_at_least '(^|[[:space:]])(movd|mov(b|zbl)?)[[:space:]]' 1 \
                              "$temporary/reduction_${lane_kind}_${operation}.txt" \
                              "SSE2 ${lane_kind} ${operation} byte result transfer"
                        fi
                    done
                    ;;
                u16|i16)
                    for operation in reduce_add_wrap reduce_min reduce_max; do
                        require_pattern '(^|[[:space:]])pextrw[[:space:]]' \
                          "$temporary/reduction_${lane_kind}_${operation}.txt" \
                          "SSE2 ${lane_kind} ${operation} result extraction"
                        #  pextrw already zero-extends the lane into a general
                        #  register, so the word never reaches a private buffer.
                        forbid_pattern '(^|[[:space:]])mov(w)?[[:space:]]+%(ax|bx|cx|dx|si|di|r(8|9|10|11|12|13|14|15)w),[[:space:]]*-?(0x)?[0-9a-f]*\(' \
                          "$temporary/reduction_${lane_kind}_${operation}.txt" \
                          "SSE2 ${lane_kind} ${operation} word result store"
                    done
                    ;;
                u64|i64)
                    for operation in reduce_add_wrap reduce_min reduce_max; do
                        require_pattern '(^|[[:space:]])movq[[:space:]]' \
                          "$temporary/reduction_${lane_kind}_${operation}.txt" \
                          "SSE2 ${lane_kind} ${operation} result extraction"
                    done
                    ;;
            esac
            case "$lane_kind" in
                i8)
                    for operation in reduce_min reduce_max; do
                        require_count '(^|[[:space:]])pcmpgtb[[:space:]]' "$stages" \
                          "$temporary/reduction_${lane_kind}_${operation}.txt" \
                          "complete signed-byte comparison tree in ${lane_kind} ${operation}"
                    done
                    ;;
                u16)
                    for operation in reduce_min reduce_max; do
                        require_count '(^|[[:space:]])pcmpgtw[[:space:]]' "$stages" \
                          "$temporary/reduction_${lane_kind}_${operation}.txt" \
                          "complete unsigned-word comparison tree in ${lane_kind} ${operation}"
                        require_count '(^|[[:space:]])pxor[[:space:]]' "$((2 * stages))" \
                          "$temporary/reduction_${lane_kind}_${operation}.txt" \
                          "sign-bit bias in every ${lane_kind} ${operation} comparison stage"
                    done
                    ;;
                u32|i32)
                    for operation in reduce_min reduce_max; do
                        require_count '(^|[[:space:]])pcmpgtd[[:space:]]' "$stages" \
                          "$temporary/reduction_${lane_kind}_${operation}.txt" \
                          "complete dword comparison tree in ${lane_kind} ${operation}"
                        if [ "$lane_kind" = u32 ]; then
                            require_count '(^|[[:space:]])pxor[[:space:]]' "$((2 * stages))" \
                              "$temporary/reduction_${lane_kind}_${operation}.txt" \
                              "sign-bit bias in every ${lane_kind} ${operation} comparison stage"
                        fi
                    done
                    ;;
                u64|i64)
                    for operation in reduce_min reduce_max; do
                        require_count '(^|[[:space:]])pcmpgtd[[:space:]]' "$((2 * stages))" \
                          "$temporary/reduction_${lane_kind}_${operation}.txt" \
                          "high- and low-dword comparisons in ${lane_kind} ${operation}"
                        require_count '(^|[[:space:]])pcmpeqd[[:space:]]' "$stages" \
                          "$temporary/reduction_${lane_kind}_${operation}.txt" \
                          "high-dword equality gate in ${lane_kind} ${operation}"
                        if [ "$lane_kind" = u64 ]; then
                            bias_count=$((4 * stages))
                        else
                            bias_count=$((2 * stages))
                        fi
                        require_count '(^|[[:space:]])pxor[[:space:]]' "$bias_count" \
                          "$temporary/reduction_${lane_kind}_${operation}.txt" \
                          "unsigned low-dword comparison bias in ${lane_kind} ${operation}"
                        require_count '(^|[[:space:]])pand[[:space:]]' "$((2 * stages))" \
                          "$temporary/reduction_${lane_kind}_${operation}.txt" \
                          "equality-gated low comparison and selected-value mask in ${lane_kind} ${operation}"
                        require_count '(^|[[:space:]])por[[:space:]]' "$((2 * stages))" \
                          "$temporary/reduction_${lane_kind}_${operation}.txt" \
                          "lexicographic comparison and selected-value merge in ${lane_kind} ${operation}"
                    done
                    ;;
            esac
        done <<'EOF'
u8   none paddb 4 byte_unsigned
i8   __2 paddb 4 compare_select
u16  __3 paddw 3 compare_select
i16  __4 paddw 3 word_signed
u32  __5 paddd 2 compare_select
i32  __6 paddd 2 compare_select
u64  __7 paddq 1 compare_select
i64  __8 paddq 1 compare_select
EOF
        while read -r operation source target instructions; do
            symbol="flyology_simd__backends__native__${operation}"
            extract_symbol "$symbol" "$temporary/native.txt" \
              "$temporary/conversion_${operation}_${source}_${target}.txt"
            old_ifs=$IFS
            IFS=,
            set -- $instructions
            IFS=$old_ifs
            for instruction in "$@"; do
                require_pattern "$instruction" \
                  "$temporary/conversion_${operation}_${source}_${target}.txt" \
                  "SSE2 ${operation} ${source} to ${target} lowering"
            done
            forbid_pattern '(^|[[:space:]])call|flyology_simd__(widen|narrow)' \
              "$temporary/conversion_${operation}_${source}_${target}.txt" \
              "scalar or out-of-line helper in ${operation} ${source} to ${target}"
        done <<'EOF'
widen_low             u8x16  u16x8  punpcklbw
widen_high            u8x16  u16x8  punpckhbw
widen_low__2          i8x16  i16x8  pcmpgtb,punpcklbw
widen_high__2         i8x16  i16x8  pcmpgtb,punpckhbw
widen_low__3          u16x8  u32x4  punpcklwd
widen_high__3         u16x8  u32x4  punpckhwd
widen_low__4          i16x8  i32x4  pcmpgtw,punpcklwd
widen_high__4         i16x8  i32x4  pcmpgtw,punpckhwd
widen_low__5          u32x4  u64x2  punpckldq
widen_high__5         u32x4  u64x2  punpckhdq
widen_low__6          i32x4  i64x2  pcmpgtd,punpckldq
widen_high__6         i32x4  i64x2  pcmpgtd,punpckhdq
widen_low__7          f32x4  f64x2  cvtps2pd
widen_high__7         f32x4  f64x2  pshufd,cvtps2pd
narrow_truncate       u16x8  u8x16  packuswb
narrow_saturate       u16x8  u8x16  psrlw,pcmpeqw,pandn,packuswb
narrow_truncate__2    i16x8  i8x16  packuswb
narrow_saturate__2    i16x8  i8x16  packsswb
narrow_truncate__3    u32x4  u16x8  pshuflw,pshufhw,pshufd,punpcklqdq
narrow_saturate__3    u32x4  u16x8  psrld,pcmpeqd,pandn,punpcklqdq
narrow_truncate__4    i32x4  i16x8  pshuflw,pshufhw,pshufd,punpcklqdq
narrow_saturate__4    i32x4  i16x8  packssdw
narrow_truncate__5    u64x2  u32x4  pshufd,punpcklqdq
narrow_saturate__5    u64x2  u32x4  psrlq,pcmpeqd,pandn,pshufd,punpcklqdq
narrow_truncate__6    i64x2  i32x4  pshufd,punpcklqdq
narrow_saturate__6    i64x2  i32x4  psrad,pcmpeqd,pandn,pshufd,punpcklqdq
narrow_saturate__7    i16x8  u8x16  packuswb
narrow_saturate__8    i32x4  u16x8  pcmpgtd,pandn,pshufd,punpcklqdq
narrow_saturate__9    i64x2  u32x4  psrad,pcmpeqd,pandn,pshufd,punpcklqdq
narrow_round          f64x2  f32x4  cvtpd2ps,movlhps
EOF
        require_count '(^|[[:space:]])cvtpd2ps[[:space:]]' 2 \
          "$temporary/conversion_narrow_round_f64x2_f32x4.txt" \
          'two SSE2 binary64-to-binary32 conversions in Narrow_Round'
        while read -r symbol source target convert count required; do
            output="$temporary/conversion_${symbol}_${source}_${target}.txt"
            extract_symbol "flyology_simd__backends__native__${symbol}" \
              "$temporary/native.txt" "$output"
            require_count "(^|[[:space:]])${convert}[[:space:]]" "$count" \
              "$output" \
              "complete packed conversion in ${source} to ${target} ${symbol}"
            old_ifs=$IFS
            IFS=,
            set -- $required
            IFS=$old_ifs
            for instruction in "$@"; do
                require_pattern "${instruction}[[:space:]]" \
                  "$output" \
                  "SSE2 ${instruction} in ${source} to ${target} ${symbol}"
            done
            forbid_pattern '(^|[[:space:]])call[[:space:]]|flyology_simd__convert_|(ld|st)mxcsr' \
              "$output" \
              "scalar helper or floating-control write in ${source} to ${target} ${symbol}"
        done <<'EOF'
convert_round                         i32x4 f32x4 cvtdq2ps  1 cvtdq2ps
convert_round__2                      u32x4 f32x4 cvtdq2ps  2 pcmpgtd,psrld,addps,pandn
convert_truncate_saturate             f32x4 i32x4 cvttps2dq 1 cmpleps,cmpunordps,pandn
convert_truncate_saturate__2          f32x4 u32x4 cvttps2dq 2 cmpleps,cmpltps,subps,paddd,pandn
EOF
        while read -r operation source target convert count required; do
            output="$temporary/conversion_${operation}_${source}_${target}.txt"
            extract_leaf_or_probe "flyology_simd__backends__native__${operation}" \
              "$temporary/native.txt" \
              "$(conversion_probe_symbol "$source" "$target" "$operation")" \
              "$temporary/integer-conversion-probe.txt" "$output"
            require_count "(^|[[:space:]])${convert}[[:space:]]" "$count" \
              "$output" \
              "${count} conversion instruction sites in ${source} to ${target} ${operation}"
            printf '%s\n' "$required" | tr ',' '\n' | while read -r instruction; do
                require_pattern "${instruction}[[:space:]]" \
                  "$output" \
                  "x86-64 ${instruction} in ${source} to ${target} ${operation}"
            done
            forbid_pattern '(^|[[:space:]])call[[:space:]]|flyology_simd__convert_|(ld|st)mxcsr' \
              "$output" \
              "portable helper or floating-control write in ${source} to ${target} ${operation}"
        done <<'EOF'
convert_round__3                      i64x2 f64x2 cvtsi2sd    2 movq,psrldq,unpcklpd
convert_round__4                      u64x2 f64x2 cvtsi2sd    4 test(q)?,shr(q)?,and(q)?,or(q)?,addsd,psrldq,unpcklpd
convert_truncate_saturate__3          f64x2 i64x2 cvttsd2si  2 movabs(q)?,and(q)?,cmp(q)?,psrldq,punpcklqdq
convert_truncate_saturate__4          f64x2 u64x2 cvttsd2si  4 test(q)?,cmp(q)?,subsd,or(q)?,psrldq,punpcklqdq
EOF
        while read -r suffix source target compare shift; do
            if [ "$suffix" = base ]; then
                operation=convert_saturate
            else
                operation="convert_saturate${suffix}"
            fi
            extract_leaf_or_probe "flyology_simd__backends__native__${operation}" \
              "$temporary/native.txt" \
              "$(conversion_probe_symbol "$source" "$target" convert_saturate)" \
              "$temporary/integer-conversion-probe.txt" \
              "$temporary/conversion_${operation}_${source}_${target}.txt"
            require_pattern "$compare" \
              "$temporary/conversion_${operation}_${source}_${target}.txt" \
              "SSE2 sign-mask derivation in ${source} to ${target} Convert_Saturate"
            require_pattern '(^|[[:space:]])pandn[[:space:]]' \
              "$temporary/conversion_${operation}_${source}_${target}.txt" \
              "SSE2 clamped selection in ${source} to ${target} Convert_Saturate"
            if [ "$shift" != none ]; then
                require_pattern "$shift" \
                  "$temporary/conversion_${operation}_${source}_${target}.txt" \
                  "SSE2 signed-maximum construction in ${source} to ${target} Convert_Saturate"
                require_pattern '(^|[[:space:]])por[[:space:]]' \
                  "$temporary/conversion_${operation}_${source}_${target}.txt" \
                  "SSE2 signed-maximum selection in ${source} to ${target} Convert_Saturate"
            fi
            forbid_pattern '(^|[[:space:]])call|flyology_simd__convert_saturate' \
              "$temporary/conversion_${operation}_${source}_${target}.txt" \
              "scalar or out-of-line helper in ${source} to ${target} Convert_Saturate"
        done <<'EOF'
base   i8x16  u8x16  pcmpgtb none
__2    u8x16  i8x16  pcmpgtb psrlw
__3    i16x8  u16x8  pcmpgtw none
__4    u16x8  i16x8  pcmpgtw psrlw
__5    i32x4  u32x4  pcmpgtd none
__6    u32x4  i32x4  pcmpgtd psrld
__7    i64x2  u64x2  psrad none
__8    u64x2  i64x2  psrad psrlq
EOF
        while read -r kind operation source target suffix arity; do
            [ -n "$kind" ] || continue
            selected_symbol=$operation
            if [ "$suffix" != none ]; then
                selected_symbol="${operation}__${suffix}"
            fi
            leaf="$temporary/x86_integer_conversion_${kind}_${operation}.txt"
            #  The conversion leaves take and return registers and inline into
            #  their probe, so no fixed-register transfer survives to count;
            #  the exact instruction is asserted below instead.
            extract_leaf_or_probe "flyology_simd__backends__native__${selected_symbol}" \
              "$temporary/native.txt" \
              "integer_conversion_codegen_probe__${kind}_${operation}" \
              "$temporary/integer-conversion-probe.txt" "$leaf"
            require_count '(^|[[:space:]])movdqu[[:space:]]+%xmm[0-9]+,[[:space:]]*[^,]*\([^)]*\)' \
              0 "$leaf" "no result store in register-operand ${kind} ${operation}"
            forbid_pattern '(^|[[:space:]])(callq?|jmpq?|j(a|ae|b|be|c|e|g|ge|l|le|na|nae|nb|nbe|nc|ne|ng|nge|nl|nle|no|np|ns|nz|o|p|pe|po|s|z))[[:space:]]' \
              "$leaf" "branch or helper in ${kind} ${operation} leaf"
        done <scripts/probes/integer_conversion_codegen_cases.txt
        require_pattern 'psub(b|w|d|q)' "$(native_and_probes)" 'SSE2 wrapping subtraction family'
        require_pattern 'paddusb' "$(native_and_probes)" 'SSE2 saturating byte add'
        require_pattern 'paddusw' "$(native_and_probes)" 'SSE2 unsigned saturating 16-bit add'
        require_pattern 'paddsw' "$(native_and_probes)" 'SSE2 signed saturating 16-bit add'
        require_pattern 'psubusb' "$(native_and_probes)" 'SSE2 saturating byte subtract'
        require_pattern 'pmullw' "$(native_and_probes)" 'SSE2 8/16-bit multiplication composition'
        require_pattern 'pmuludq' "$(native_and_probes)" 'SSE2 32/64-bit multiplication composition'
        require_pattern 'pcmpgt(b|w|d)' "$(native_and_probes)" 'SSE2 ordered integer comparisons'
        require_pattern 'psll(w|d|q)' "$(native_and_probes)" 'SSE2 logical left shifts'
        require_pattern 'psrl(w|d|q)' "$(native_and_probes)" 'SSE2 logical right shifts'
        require_pattern 'psra(w|d)' "$(native_and_probes)" 'SSE2 arithmetic right shifts'
        extract_leaf_or_probe 'native_table_lookup_u8x16' "$temporary/native.txt" \
          'table_lookup_codegen_probe__lookup' "$temporary/table-lookup-probe.txt" \
          "$temporary/table_lookup.txt"
        require_count '(^|[[:space:]])pcmpeqb[[:space:]]' 16 \
          "$temporary/table_lookup.txt" 'sixteen SSE2 table-index comparisons'
        require_count '(^|[[:space:]])punpcklbw[[:space:]]' 16 \
          "$temporary/table_lookup.txt" 'sixteen SSE2 table-byte broadcasts'
        require_count '(^|[[:space:]])punpcklwd[[:space:]]' 16 \
          "$temporary/table_lookup.txt" 'sixteen SSE2 table-byte word broadcasts'
        require_count '(^|[[:space:]])pshufd[[:space:]]' 16 \
          "$temporary/table_lookup.txt" 'sixteen SSE2 table-byte dword broadcasts'
        require_count '(^|[[:space:]])pand[[:space:]]' 16 \
          "$temporary/table_lookup.txt" 'sixteen SSE2 lookup masks'
        require_count '(^|[[:space:]])por[[:space:]]' 16 \
          "$temporary/table_lookup.txt" 'sixteen SSE2 lookup merges'
        require_count '(^|[[:space:]])paddb[[:space:]]' 16 \
          "$temporary/table_lookup.txt" 'sixteen SSE2 selector increments'
        require_count '(^|[[:space:]])pxor[[:space:]]' 2 \
          "$temporary/table_lookup.txt" 'SSE2 result and selector zero initialization'
        require_count '(^|[[:space:]])pcmpeqd[[:space:]]' 1 \
          "$temporary/table_lookup.txt" 'SSE2 all-ones increment construction'
        require_count '(^|[[:space:]])psrlw[[:space:]]' 1 \
          "$temporary/table_lookup.txt" 'SSE2 one-bit increment construction'
        require_count '(^|[[:space:]])packuswb[[:space:]]' 1 \
          "$temporary/table_lookup.txt" 'SSE2 byte increment construction'
        forbid_pattern '(^|[[:space:]])call[[:space:]]|flyology_simd__table_lookup' \
          "$temporary/table_lookup.txt" 'portable or out-of-line x86-64 Table_Lookup helper'
        for lane_shape in u8x16 i8x16 u16x8 i16x8 u32x4 i32x4 f32x4 u64x2 i64x2 f64x2; do
            lane_kind=${lane_shape%x*}
            extract_symbol "native_permute_${lane_shape}" \
              "$temporary/native.txt" "$temporary/permute_${lane_kind}.txt"
            require_count '(^|[[:space:]])pcmpeqb[[:space:]]' 16 \
              "$temporary/permute_${lane_kind}.txt" \
              "sixteen SSE2 selector comparisons in ${lane_kind} one-source permutation"
            require_count '(^|[[:space:]])paddb[[:space:]]' 16 \
              "$temporary/permute_${lane_kind}.txt" \
              "sixteen SSE2 selector increments in ${lane_kind} one-source permutation"
            for instruction in punpcklbw punpcklwd pshufd pand por; do
                require_count "(^|[[:space:]])${instruction}[[:space:]]" 16 \
                  "$temporary/permute_${lane_kind}.txt" \
                  "sixteen SSE2 ${instruction} stages in ${lane_kind} one-source permutation"
            done
            require_count '(^|[[:space:]])pxor[[:space:]]' 2 \
              "$temporary/permute_${lane_kind}.txt" \
              "SSE2 result and selector zero initialization in ${lane_kind} one-source permutation"
            for instruction in pcmpeqd psrlw packuswb; do
                require_count "(^|[[:space:]])${instruction}[[:space:]]" 1 \
                  "$temporary/permute_${lane_kind}.txt" \
                  "SSE2 selector increment construction in ${lane_kind} one-source permutation"
            done
            forbid_pattern '(^|[[:space:]])call[[:space:]]|flyology_simd__permute_lanes' \
              "$temporary/permute_${lane_kind}.txt" \
              "portable or out-of-line ${lane_kind} one-source permutation"
            extract_symbol "native_permute_2_${lane_shape}" \
              "$temporary/native.txt" "$temporary/permute_2_${lane_kind}.txt"
            require_count '(^|[[:space:]])pcmpeqb[[:space:]]' 32 \
              "$temporary/permute_2_${lane_kind}.txt" \
              "thirty-two SSE2 selector comparisons in ${lane_kind} two-source permutation"
            require_count '(^|[[:space:]])paddb[[:space:]]' 32 \
              "$temporary/permute_2_${lane_kind}.txt" \
              "thirty-two SSE2 selector increments in ${lane_kind} two-source permutation"
            for instruction in punpcklbw punpcklwd pshufd pand por; do
                require_count "(^|[[:space:]])${instruction}[[:space:]]" 32 \
                  "$temporary/permute_2_${lane_kind}.txt" \
                  "thirty-two SSE2 ${instruction} stages in ${lane_kind} two-source permutation"
            done
            require_count '(^|[[:space:]])pxor[[:space:]]' 2 \
              "$temporary/permute_2_${lane_kind}.txt" \
              "SSE2 result and selector zero initialization in ${lane_kind} two-source permutation"
            for instruction in pcmpeqd psrlw packuswb; do
                require_count "(^|[[:space:]])${instruction}[[:space:]]" 1 \
                  "$temporary/permute_2_${lane_kind}.txt" \
                  "SSE2 selector increment construction in ${lane_kind} two-source permutation"
            done
            forbid_pattern '(^|[[:space:]])call[[:space:]]|flyology_simd__permute_lanes' \
              "$temporary/permute_2_${lane_kind}.txt" \
              "portable or out-of-line ${lane_kind} two-source permutation"
        done
        require_native_route 'flyology_simd__backends__native__native_permute_[a-z0-9]+$' 10 \
          "$temporary/permute-undefined.txt" "$temporary/permute-probe.txt" \
          'all ten one-source Native permutation leaves in caller probes'
        require_native_route 'flyology_simd__backends__native__native_permute_2_[a-z0-9]+$' 10 \
          "$temporary/permute-undefined.txt" "$temporary/permute-probe.txt" \
          'all ten two-source Native permutation leaves in caller probes'
        forbid_pattern 'flyology_simd__backends__native__permute_lanes|flyology_simd__permute_lanes' \
          "$temporary/permute-undefined.txt" \
          'Native dispatcher or portable permutation retained in x86 caller probes'
        while read -r lane_kind lane_shape; do
            for operation in compress expand; do
                output="$temporary/${lane_kind}_${operation}.txt"
                extract_symbol "permute_codegen_probe__${lane_kind}_${operation}" \
                  "$temporary/permute-probe.txt" "$output"
                require_route_or_inlined "flyology_simd__backends__native__native_permute_${lane_shape}" \
                  "$output" \
                  "matching SSE2 permutation leaf in ${lane_kind} ${operation} caller"
                forbid_pattern 'flyology_simd__backends__native__(compress|expand)|flyology_simd__(compress|expand)' \
                  "$output" \
                  "public Native or portable compact operation in ${lane_kind} ${operation} caller"
            done
        done <<'EOF'
u8 u8x16
i8 i8x16
u16 u16x8
i16 i16x8
u32 u32x4
i32 i32x4
f32 f32x4
u64 u64x2
i64 i64x2
f64 f64x2
EOF
        forbid_pattern 'flyology_simd__(compress|expand)' \
          "$temporary/native-undefined.txt" \
          'portable compact operation retained in x86 Native object'
        for direction in low high; do
            instruction=psrldq
            if [ "$direction" = high ]; then instruction=pslldq; fi
            for lane_kind in u8 i8 u16 i16 u32 i32 u64 i64 f32 f64; do
                symbol="slide_codegen_probe__${lane_kind}_${direction}"
                output="$temporary/slide-${lane_kind}-${direction}.txt"
                extract_symbol "$symbol" "$temporary/slide-probe.txt" "$output"
                require_pattern "(^|[[:space:]])${instruction}[[:space:]]" "$output" \
                  "SSE2 immediate lane movement in ${lane_kind} ${direction} caller"
                forbid_pattern 'flyology_simd__(zero|slide_lanes_toward_(low|high))' \
                  "$output" \
                  "portable zero or lane-slide call in ${lane_kind} ${direction} caller"
            done
        done
        for entry in \
          'shl u8x16 psllw packuswb' 'shr u8x16 psrlw packuswb' \
          'shl i8x16 psllw packuswb' 'shr i8x16 psrlw packuswb' \
          'shl u16x8 psllw none' 'shr u16x8 psrlw none' \
          'shl i16x8 psllw none' 'shr i16x8 psrlw none' \
          'shl u32x4 pslld none' 'shr u32x4 psrld none' \
          'shl i32x4 pslld none' 'shr i32x4 psrld none' \
          'shl u64x2 psllq none' 'shr u64x2 psrlq none' \
          'shl i64x2 psllq none' 'shr i64x2 psrlq none'; do
            set -- $entry
            operation=$1
            lane=$2
            instruction=$3
            secondary=$4
            symbol="native_${operation}_${lane}"
            if [ "$lane" = u8x16 ]; then
                case "$operation" in
                    shl) symbol='flyology_simd__backends__native__shift_left_logical' ;;
                    shr) symbol='flyology_simd__backends__native__shift_right_logical' ;;
                esac
                forbidden='flyology_simd__(zero|shift_(left|right)_logical)'
            else
                forbidden='(^|[[:space:]])call[[:space:]]|flyology_simd__(zero|shift_(left|right)_logical)'
            fi
            extract_symbol "$symbol" \
              "$temporary/native.txt" "$temporary/${operation}-${lane}.txt"
            require_pattern "(^|[[:space:]])${instruction}[[:space:]]" \
              "$temporary/${operation}-${lane}.txt" \
              "SSE2 ${instruction} in ${lane} logical shift"
            if [ "$secondary" != none ]; then
                require_pattern "(^|[[:space:]])${secondary}[[:space:]]" \
                  "$temporary/${operation}-${lane}.txt" \
                  "SSE2 byte repacking in ${lane} logical shift"
                for widening in pxor punpcklbw punpckhbw; do
                    require_pattern "(^|[[:space:]])${widening}[[:space:]]" \
                      "$temporary/${operation}-${lane}.txt" \
                      "SSE2 byte widening step ${widening} in ${lane} logical shift"
                done
            fi
            forbid_pattern "$forbidden" \
              "$temporary/${operation}-${lane}.txt" \
              "portable or out-of-line helper in ${lane} logical shift"
        done
        for entry in 'i8x16 psraw packsswb' 'i16x8 psraw none' 'i32x4 psrad none'; do
            set -- $entry
            lane=$1
            instruction=$2
            secondary=$3
            extract_symbol "native_sar_${lane}" \
              "$temporary/native.txt" "$temporary/${lane}-sar.txt"
            require_pattern "(^|[[:space:]])${instruction}[[:space:]]" \
              "$temporary/${lane}-sar.txt" \
              "inlined SSE2 arithmetic right shift for ${lane}"
            if [ "$secondary" != none ]; then
                require_pattern "(^|[[:space:]])${secondary}[[:space:]]" \
                  "$temporary/${lane}-sar.txt" \
                  "SSE2 signed-byte repacking for ${lane}"
            fi
            forbid_pattern '(^|[[:space:]])call[[:space:]]|flyology_simd__shift_right_arithmetic' \
              "$temporary/${lane}-sar.txt" \
              "portable or out-of-line arithmetic right shift for ${lane}"
        done
        for instruction in pxor punpcklbw punpckhbw psllw; do
            require_pattern "(^|[[:space:]])${instruction}[[:space:]]" \
              "$temporary/i8x16-sar.txt" \
              "SSE2 signed-byte widening step ${instruction} in I8x16 arithmetic right shift"
        done
        extract_symbol 'native_sar_i64x2' "$temporary/native.txt" \
          "$temporary/sar-i64x2.txt"
        for instruction in pshufd psrad psrlq pxor por; do
            require_pattern "(^|[[:space:]])${instruction}[[:space:]]" \
              "$temporary/sar-i64x2.txt" \
              "SSE2 ${instruction} in I64x2 Shift_Right_Arithmetic"
        done
        forbid_pattern '(^|[[:space:]])call[[:space:]]|flyology_simd__shift_right_arithmetic' \
          "$temporary/sar-i64x2.txt" \
          'portable or out-of-line helper in I64x2 Shift_Right_Arithmetic'
        require_pattern 'pandn' "$(native_and_probes)" 'SSE2 mask selection'
        require_pattern 'punpckl(bw|wd|dq|qdq)' "$(native_and_probes)" 'SSE2 interleave family'
        require_pattern 'pshuf(d|lw|hw)' "$(native_and_probes)" 'SSE2 reverse/shuffle family'
        extract_symbol 'slide_codegen_probe__u8_toward_low' "$temporary/slide-probe.txt" "$temporary/probe_u8_low.txt"
        extract_symbol 'slide_codegen_probe__u8_toward_high' "$temporary/slide-probe.txt" "$temporary/probe_u8_high.txt"
        extract_symbol 'slide_codegen_probe__u16_toward_low' "$temporary/slide-probe.txt" "$temporary/probe_u16_low.txt"
        extract_symbol 'slide_codegen_probe__u32_toward_low' "$temporary/slide-probe.txt" "$temporary/probe_u32_low.txt"
        extract_symbol 'slide_codegen_probe__f32_toward_low' "$temporary/slide-probe.txt" "$temporary/probe_f32_low.txt"
        extract_symbol 'slide_codegen_probe__f32_toward_high' "$temporary/slide-probe.txt" "$temporary/probe_f32_high.txt"
        extract_symbol 'slide_codegen_probe__f64_toward_high' "$temporary/slide-probe.txt" "$temporary/probe_f64_high.txt"
        require_pattern 'psrldq.*[$](0x)?0*1([^[:xdigit:]]|$)' "$temporary/probe_u8_low.txt" 'constant U8 slide toward low in caller'
        require_pattern 'pslldq.*[$](0x)?0*1([^[:xdigit:]]|$)' "$temporary/probe_u8_high.txt" 'constant U8 slide toward high in caller'
        require_pattern 'psrldq.*[$](0x)?0*2([^[:xdigit:]]|$)' "$temporary/probe_u16_low.txt" 'constant U16 lane scaling in caller'
        require_pattern 'psrldq.*[$](0x)?0*4([^[:xdigit:]]|$)' "$temporary/probe_u32_low.txt" 'constant U32 lane scaling in caller'
        require_pattern 'psrldq.*[$](0x)?0*4([^[:xdigit:]]|$)' "$temporary/probe_f32_low.txt" 'constant F32 slide toward low in caller'
        require_pattern 'pslldq.*[$](0x)?0*4([^[:xdigit:]]|$)' "$temporary/probe_f32_high.txt" 'constant F32 slide toward high in caller'
        require_pattern 'pslldq.*[$](0x)?0*8([^[:xdigit:]]|$)' "$temporary/probe_f64_high.txt" 'constant F64 lane scaling in caller'
        forbid_pattern 'flyology_simd__backends__native__slide_lanes' "$temporary/slide-probe.txt" 'lane-slide dispatcher call in constant-count probe'
        require_pattern 'addps' "$(native_and_probes)" 'SSE floating32 addition'
        require_pattern 'addpd' "$(native_and_probes)" 'SSE2 floating64 addition'
        require_pattern 'mul(ps|pd)' "$(native_and_probes)" 'SSE/SSE2 floating multiplication'
        require_pattern 'div(ps|pd)' "$(native_and_probes)" 'SSE/SSE2 floating division'
        require_pattern 'cmp(unord|eq|lt|le)(ps|pd)' "$(native_and_probes)" 'SSE/SSE2 floating comparisons'
        require_pattern 'movdqu' "$(native_and_probes)" 'unaligned SSE2 load/store'
        require_pattern 'movdqa' "$(native_and_probes)" 'aligned SSE2 load/store'
        extract_symbol 'wide_codegen_probe__u8_add' "$temporary/wide-probe.txt" "$temporary/wide_u8_add.txt"
        extract_symbol 'wide_codegen_probe__f32_multiply' "$temporary/wide-probe.txt" "$temporary/wide_f32_multiply.txt"
        for precision in f32 f64; do
            for operation in add subtract multiply divide min_number max_number; do
                extract_symbol "wide_codegen_probe__${precision}_${operation}" \
                  "$temporary/wide-probe.txt" \
                  "$temporary/wide_${precision}_${operation}.txt"
            done
        done
        extract_symbol 'wide_codegen_probe__f32_to_u32_bits' "$temporary/wide-probe.txt" "$temporary/wide_f32_to_u32.txt"
        extract_symbol 'wide_codegen_probe__u8_widen_low' "$temporary/wide-probe.txt" "$temporary/wide_u8_widen.txt"
        extract_symbol 'wide_codegen_probe__u16_narrow_saturate' "$temporary/wide-probe.txt" "$temporary/wide_u16_narrow.txt"
        extract_symbol 'wide_codegen_probe__i32_to_f32' "$temporary/wide-probe.txt" "$temporary/wide_i32_to_f32.txt"
        extract_symbol 'wide_codegen_probe__u8_table_lookup' "$temporary/wide-probe.txt" "$temporary/wide_u8_table_lookup.txt"
        extract_symbol 'wide_codegen_probe__u8_horizontal_sum' "$temporary/wide-probe.txt" "$temporary/wide_u8_horizontal_sum.txt"
        extract_symbol 'wide_codegen_probe__u8_permute' "$temporary/wide-probe.txt" "$temporary/wide_u8_permute.txt"
        extract_symbol 'wide_codegen_probe__u16_permute_2' "$temporary/wide-probe.txt" "$temporary/wide_u16_permute_2.txt"
        extract_symbol 'wide_codegen_probe__f32_permute' "$temporary/wide-probe.txt" "$temporary/wide_f32_permute.txt"
        extract_symbol 'wide_codegen_probe__f64_permute_2' "$temporary/wide-probe.txt" "$temporary/wide_f64_permute_2.txt"
        extract_symbol 'wide_codegen_probe__u8_reverse' "$temporary/wide-probe.txt" "$temporary/wide_u8_reverse.txt"
        extract_symbol 'wide_codegen_probe__u16_interleave_low' "$temporary/wide-probe.txt" "$temporary/wide_u16_interleave.txt"
        extract_symbol 'wide_codegen_probe__f32_deinterleave_odd' "$temporary/wide-probe.txt" "$temporary/wide_f32_deinterleave.txt"
        extract_symbol 'wide_codegen_probe__f64_slide_low_one' "$temporary/wide-probe.txt" "$temporary/wide_f64_slide.txt"
        for lane_kind in u8 i8; do
            for operation in equal less less_equal greater greater_equal select; do
                extract_symbol "wide_codegen_probe__${lane_kind}_${operation}" \
                  "$temporary/wide-probe.txt" \
                  "$temporary/wide_${lane_kind}_${operation}.txt"
            done
        done
        if [ "$wide_backend" = composed ]; then
            for vector_kind in u8x32 i8x32 u16x16 i16x16 u32x8 i32x8 u64x4 i64x4 f32x8 f64x4; do
                case "$vector_kind" in
                    u8x32) half_kind=u8x16; select_leaf='backends__native__select_value'; zero_leaf= ;;
                    i8x32) half_kind=i8x16; select_leaf='backends__native__native_select_i8x16'; zero_leaf='backends__native__native_zero_i8x16' ;;
                    u16x16) half_kind=u16x8; select_leaf='backends__native__native_select_u16x8'; zero_leaf='backends__native__native_zero_u16x8' ;;
                    i16x16) half_kind=i16x8; select_leaf='backends__native__native_select_i16x8'; zero_leaf='backends__native__native_zero_i16x8' ;;
                    u32x8) half_kind=u32x4; select_leaf='backends__native__native_select_u32x4'; zero_leaf='backends__native__native_zero_u32x4' ;;
                    i32x8) half_kind=i32x4; select_leaf='backends__native__native_select_i32x4'; zero_leaf='backends__native__native_zero_i32x4' ;;
                    u64x4) half_kind=u64x2; select_leaf='backends__native__native_select_u64x2'; zero_leaf='backends__native__native_zero_u64x2' ;;
                    i64x4) half_kind=i64x2; select_leaf='backends__native__native_select_i64x2'; zero_leaf='backends__native__native_zero_i64x2' ;;
                    f32x8) half_kind=f32x4; select_leaf='backends__native__native_select_f32x4'; zero_leaf='backends__native__native_zero_f32x4' ;;
                    f64x4) half_kind=f64x2; select_leaf='backends__native__native_select_f64x2'; zero_leaf='backends__native__native_zero_f64x2' ;;
                esac
                for operation in permute_1 reverse; do
                    extract_symbol "wide_movement_codegen_probe__${vector_kind}_${operation}" \
                      "$temporary/wide-movement-probe.txt" \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt"
                    require_at_most "backends__native__native_permute_2_${half_kind}" 2 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "two exact selected permutations in ${vector_kind} ${operation} caller"
                    require_at_most 'backends__native__native_permute_2_' 2 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "no mismatched permutation in ${vector_kind} ${operation} caller"
                done
                for operation in permute_2 interleave_low interleave_high deinterleave_even deinterleave_odd; do
                    extract_symbol "wide_movement_codegen_probe__${vector_kind}_${operation}" \
                      "$temporary/wide-movement-probe.txt" \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt"
                    require_at_most "backends__native__native_permute_2_${half_kind}" 4 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "four exact selected permutations in ${vector_kind} ${operation} caller"
                    require_at_most "$select_leaf" 2 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "two exact selected source choices in ${vector_kind} ${operation} caller"
                    require_at_most 'backends__native__native_permute_2_' 4 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "no mismatched permutation in ${vector_kind} ${operation} caller"
                    require_at_most 'backends__native(__select_value|__native_select_)' 2 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "no mismatched source choice in ${vector_kind} ${operation} caller"
                done
                for operation in slide_low slide_high; do
                    extract_symbol "wide_movement_codegen_probe__${vector_kind}_${operation}" \
                      "$temporary/wide-movement-probe.txt" \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt"
                    require_at_most "backends__native__native_permute_2_${half_kind}" 2 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "two exact selected permutations in ${vector_kind} ${operation} caller"
                    require_at_most "$select_leaf" 2 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "two exact selected zero-fill choices in ${vector_kind} ${operation} caller"
                    require_at_most 'backends__native__native_permute_2_' 2 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "no mismatched permutation in ${vector_kind} ${operation} caller"
                    require_at_most 'backends__native(__select_value|__native_select_)' 2 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "no mismatched zero-fill choice in ${vector_kind} ${operation} caller"
                    if [ -n "$zero_leaf" ]; then
                        require_at_most "$zero_leaf" 1 \
                          "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                          "one exact selected zero in ${vector_kind} ${operation} caller"
                        require_at_most 'backends__native__native_zero_' 1 \
                          "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                          "no mismatched zero constructor in ${vector_kind} ${operation} caller"
                    else
                        #  Self-XOR is the zeroing idiom whatever register it
                        #  lands in.  The map, the selector and the value need
                        #  one each; the byte family's own Zero inlines here
                        #  too now, so this is a floor and the assertion that
                        #  matters is the absence of a call, just below.
                        require_at_least '(^|[[:space:]])pxor[[:space:]]+%?xmm([0-9]+),[[:space:]]*%?xmm\2' 3 \
                          "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                          "exact map, selector, and value zeroing in ${vector_kind} ${operation} caller"
                        require_at_most 'backends__native__native_zero_' 0 \
                          "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                          "no out-of-line zero constructor in ${vector_kind} ${operation} caller"
                    fi
                done
            done
        else
            for vector_kind in u8x32 i8x32 u16x16 i16x16 u32x8 i32x8 u64x4 i64x4 f32x8 f64x4; do
                for operation in permute_1 reverse slide_low slide_high; do
                    extract_symbol "wide_movement_codegen_probe__${vector_kind}_${operation}" \
                      "$temporary/wide-movement-probe.txt" \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt"
                    require_count '(^|[[:space:]])vpshufb[[:space:]]' 2 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "two byte shuffles in AVX2 ${vector_kind} ${operation} caller"
                    require_count '(^|[[:space:]])vperm2i128[[:space:]]' 1 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "one cross-half selection in AVX2 ${vector_kind} ${operation} caller"
                    require_count '(^|[[:space:]])vpcmpeqb[[:space:]]' 2 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "two mask comparisons in AVX2 ${vector_kind} ${operation} caller"
                    require_count '(^|[[:space:]])vpandn[[:space:]]' 1 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "one false-side mask selection in AVX2 ${vector_kind} ${operation} caller"
                    require_count '(^|[[:space:]])vpor[[:space:]]' 1 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "one mask merge in AVX2 ${vector_kind} ${operation} caller"
                    require_count '(^|[[:space:]])vzeroupper([[:space:]]|$)' 1 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "one vzeroupper in AVX2 ${vector_kind} ${operation} caller"
                    forbid_pattern 'flyology_simd__wide__(extract|from_lanes|permute_lanes|reverse_lanes|interleave_|deinterleave_|slide_lanes_)' \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "call or portable helper in AVX2 ${vector_kind} ${operation} caller"
                done
                for operation in permute_2 interleave_low interleave_high deinterleave_even deinterleave_odd; do
                    extract_symbol "wide_movement_codegen_probe__${vector_kind}_${operation}" \
                      "$temporary/wide-movement-probe.txt" \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt"
                    require_count '(^|[[:space:]])vpshufb[[:space:]]' 4 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "four byte shuffles in AVX2 ${vector_kind} ${operation} caller"
                    require_count '(^|[[:space:]])vperm2i128[[:space:]]' 2 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "two cross-half selections in AVX2 ${vector_kind} ${operation} caller"
                    require_count '(^|[[:space:]])vpcmpeqb[[:space:]]' 2 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "two mask comparisons in AVX2 ${vector_kind} ${operation} caller"
                    require_count '(^|[[:space:]])vpandn[[:space:]]' 3 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "three false-side mask selections in AVX2 ${vector_kind} ${operation} caller"
                    require_count '(^|[[:space:]])vpor[[:space:]]' 3 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "three mask merges in AVX2 ${vector_kind} ${operation} caller"
                    require_count '(^|[[:space:]])vzeroupper([[:space:]]|$)' 1 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "one vzeroupper in AVX2 ${vector_kind} ${operation} caller"
                    forbid_pattern 'flyology_simd__wide__(extract|from_lanes|permute_lanes|reverse_lanes|interleave_|deinterleave_|slide_lanes_)' \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "call or portable helper in AVX2 ${vector_kind} ${operation} caller"
                done
            done
        fi
        if [ "$wide_backend" = avx2 ]; then
            require_at_most '(^|[[:space:]])call' 1 "$temporary/wide_u8_add.txt" 'one isolated AVX2 byte-operation mechanism in wide caller'
            for precision in f32 f64; do
                for operation in add subtract multiply divide min_number max_number; do
                    require_at_most '(^|[[:space:]])(callq?|jmpq?)[[:space:]]' 1 \
                      "$temporary/wide_${precision}_${operation}.txt" \
                      "one isolated AVX2 ${precision} ${operation} leaf in wide caller"
                    forbid_pattern '(^|[[:space:]])(call|jmp).*backends__native|(^|[[:space:]])(call|jmp).*flyology_simd__wide__(native|float_arithmetic_mechanism)' \
                      "$temporary/wide_${precision}_${operation}.txt" \
                      "composed or public helper in AVX2 ${precision} ${operation} caller"
                done
            done
            for permute_probe in wide_u8_permute wide_f32_permute; do
                require_count 'vpshufb' 2 "$temporary/${permute_probe}.txt" \
                  "two AVX2 byte shuffles in one-source ${permute_probe} caller"
                require_count 'vperm2i128' 1 "$temporary/${permute_probe}.txt" \
                  "one AVX2 cross-half selection in one-source ${permute_probe} caller"
                require_count 'vzeroupper' 1 "$temporary/${permute_probe}.txt" \
                  "AVX2 boundary cleanup in one-source ${permute_probe} caller"
                forbid_pattern 'flyology_simd__(__wide)?__(extract|from_lanes|permute_lanes)|flyology_simd__wide__native__permute_lanes' \
                  "$temporary/${permute_probe}.txt" \
                  "scalar, per-lane, or public permutation helper in ${permute_probe} caller"
            done
            for permute_probe in wide_u16_permute_2 wide_f64_permute_2; do
                require_count 'vpshufb' 4 "$temporary/${permute_probe}.txt" \
                  "four AVX2 byte shuffles in two-source ${permute_probe} caller"
                require_count 'vperm2i128' 2 "$temporary/${permute_probe}.txt" \
                  "two AVX2 cross-half selections in two-source ${permute_probe} caller"
                require_count 'vzeroupper' 1 "$temporary/${permute_probe}.txt" \
                  "AVX2 boundary cleanup in two-source ${permute_probe} caller"
                forbid_pattern 'flyology_simd__(__wide)?__(extract|from_lanes|permute_lanes)|flyology_simd__wide__native__permute_lanes' \
                  "$temporary/${permute_probe}.txt" \
                  "scalar, per-lane, or public permutation helper in ${permute_probe} caller"
            done
            for movement_probe in wide_u8_reverse wide_f64_slide; do
                require_count 'vpshufb' 2 "$temporary/${movement_probe}.txt" \
                  "two AVX2 byte shuffles in one-source ${movement_probe} caller"
                require_count 'vperm2i128' 1 "$temporary/${movement_probe}.txt" \
                  "one AVX2 cross-half selection in one-source ${movement_probe} caller"
                require_count 'vzeroupper' 1 "$temporary/${movement_probe}.txt" \
                  "AVX2 boundary cleanup in one-source ${movement_probe} caller"
                require_pattern 'vpcmpeqb' "$temporary/${movement_probe}.txt" \
                  "AVX2 source-half mask in one-source ${movement_probe} caller"
                require_pattern 'vpandn' "$temporary/${movement_probe}.txt" \
                  "AVX2 complementary source selection in one-source ${movement_probe} caller"
                require_pattern 'vpor' "$temporary/${movement_probe}.txt" \
                  "AVX2 source merge in one-source ${movement_probe} caller"
            done
            for movement_probe in wide_u16_interleave wide_f32_deinterleave; do
                require_count 'vpshufb' 4 "$temporary/${movement_probe}.txt" \
                  "four AVX2 byte shuffles in two-source ${movement_probe} caller"
                require_count 'vperm2i128' 2 "$temporary/${movement_probe}.txt" \
                  "two AVX2 cross-half selections in two-source ${movement_probe} caller"
                require_count 'vzeroupper' 1 "$temporary/${movement_probe}.txt" \
                  "AVX2 boundary cleanup in two-source ${movement_probe} caller"
                require_pattern 'vpcmpeqb' "$temporary/${movement_probe}.txt" \
                  "AVX2 source masks in two-source ${movement_probe} caller"
                require_pattern 'vpandn' "$temporary/${movement_probe}.txt" \
                  "AVX2 complementary source selection in two-source ${movement_probe} caller"
                require_pattern 'vpor' "$temporary/${movement_probe}.txt" \
                  "AVX2 source merge in two-source ${movement_probe} caller"
            done
            for movement_probe in wide_u8_reverse wide_u16_interleave wide_f32_deinterleave wide_f64_slide; do
                forbid_pattern 'flyology_simd__(__wide)?__(extract|from_lanes|reverse_lanes|interleave|deinterleave|slide_lanes)|flyology_simd__wide__native__' \
                  "$temporary/${movement_probe}.txt" \
                  "scalar, per-lane, or public movement helper in ${movement_probe} caller"
            done
        else
            require_at_most '(^|[[:space:]])call' 2 "$temporary/wide_u8_add.txt" 'two inlined SSE2 byte-add leaves in wide caller'
        fi
        if [ "$wide_backend" = composed ]; then
            for precision in f32 f64; do
                for operation in add subtract multiply divide min_number max_number; do
                    require_at_most '(^|[[:space:]])call' 2 \
                      "$temporary/wide_${precision}_${operation}.txt" \
                      "two selected SSE ${precision} ${operation} leaves in wide caller"
                done
            done
        fi
        require_at_most '(^|[[:space:]])call' 2 "$temporary/wide_f32_to_u32.txt" 'two SSE F32-to-U32 bit-cast leaves in wide caller'
        require_at_most '(^|[[:space:]])call' 2 "$temporary/wide_u8_widen.txt" 'two selected byte-widen operations in wide caller'
        require_at_most '(^|[[:space:]])call' 2 "$temporary/wide_u16_narrow.txt" 'two selected U16-narrow operations in wide caller'
        require_at_most '(^|[[:space:]])call' 2 "$temporary/wide_i32_to_f32.txt" 'two selected I32-to-F32 conversion operations in wide caller'
        require_at_most '(^|[[:space:]])call' 1 "$temporary/wide_u8_table_lookup.txt" 'one target-selected 32-lane table-lookup mechanism in wide caller'
        require_at_most '(^|[[:space:]])call' 2 "$temporary/wide_u8_horizontal_sum.txt" 'two exact byte-sum operations in wide caller'
        for lane_kind in u8 i8 u16 i16 u32 i32 u64 i64 f32 f64; do
            case "$lane_kind" in
                u8) half_kind=u8x16; select_leaf='backends__native__select_value'; zero_leaf= ;;
                i8) half_kind=i8x16; select_leaf='backends__native__native_select_i8x16'; zero_leaf='backends__native__native_zero_i8x16' ;;
                u16) half_kind=u16x8; select_leaf='backends__native__native_select_u16x8'; zero_leaf='backends__native__native_zero_u16x8' ;;
                i16) half_kind=i16x8; select_leaf='backends__native__native_select_i16x8'; zero_leaf='backends__native__native_zero_i16x8' ;;
                u32) half_kind=u32x4; select_leaf='backends__native__native_select_u32x4'; zero_leaf='backends__native__native_zero_u32x4' ;;
                i32) half_kind=i32x4; select_leaf='backends__native__native_select_i32x4'; zero_leaf='backends__native__native_zero_i32x4' ;;
                u64) half_kind=u64x2; select_leaf='backends__native__native_select_u64x2'; zero_leaf='backends__native__native_zero_u64x2' ;;
                i64) half_kind=i64x2; select_leaf='backends__native__native_select_i64x2'; zero_leaf='backends__native__native_zero_i64x2' ;;
                f32) half_kind=f32x4; select_leaf='backends__native__native_select_f32x4'; zero_leaf='backends__native__native_zero_f32x4' ;;
                f64) half_kind=f64x2; select_leaf='backends__native__native_select_f64x2'; zero_leaf='backends__native__native_zero_f64x2' ;;
            esac
            for operation in compress expand; do
                extract_symbol "wide_compact_codegen_probe__${lane_kind}_${operation}" \
                  "$temporary/wide-compact-probe.txt" \
                  "$temporary/wide_compact_${lane_kind}_${operation}.txt"
                require_at_most "backends__native__native_permute_2_${half_kind}" 2 \
                  "$temporary/wide_compact_${lane_kind}_${operation}.txt" \
                  "two selected SSE2 permutations in Wide ${lane_kind} ${operation} caller"
                require_at_most 'backends__native__native_permute_2_' 2 \
                  "$temporary/wide_compact_${lane_kind}_${operation}.txt" \
                  "no mismatched selected permutation leaf in Wide ${lane_kind} ${operation} caller"
                require_at_most "$select_leaf" 2 \
                  "$temporary/wide_compact_${lane_kind}_${operation}.txt" \
                  "two selected SSE2 zero-fill selections in Wide ${lane_kind} ${operation} caller"
                require_at_most 'backends__native(__select_value|__native_select_)' 2 \
                  "$temporary/wide_compact_${lane_kind}_${operation}.txt" \
                  "no mismatched selected zero-fill leaf in Wide ${lane_kind} ${operation} caller"
                if [ -n "$zero_leaf" ]; then
                    require_at_most "$zero_leaf" 1 \
                      "$temporary/wide_compact_${lane_kind}_${operation}.txt" \
                      "one selected SSE2 zero construction in Wide ${lane_kind} ${operation} caller"
                else
                    require_pattern '(^|[[:space:]])pxor[[:space:]]' \
                      "$temporary/wide_compact_${lane_kind}_${operation}.txt" \
                      "inline selected SSE2 zero construction in Wide ${lane_kind} ${operation} caller"
                fi
                forbid_pattern 'flyology_simd__(__wide)?__(to_bit_mask|mask_from_bit_mask|zero)|flyology_simd__backends__native__(to_bit_mask|mask_from_bit_mask|zero)' \
                  "$temporary/wide_compact_${lane_kind}_${operation}.txt" \
                  "portable mask or zero helper in ${lane_kind} ${operation} caller"
                forbid_pattern '(^|[[:space:]])(call|jmp).*flyology_simd__wide__(compress|expand|native__)|flyology_simd__(__wide)?__(extract|from_lanes|test)' \
                  "$temporary/wide_compact_${lane_kind}_${operation}.txt" \
                  "portable or public Wide compact helper in ${lane_kind} ${operation} caller"
            done
        done
        if [ "$wide_backend" = avx2 ]; then
            for lane_kind in u8 i8; do
                for operation in equal less less_equal greater greater_equal select; do
                    require_at_most '(^|[[:space:]])(callq?|jmpq?)[[:space:]]' 1 \
                      "$temporary/wide_${lane_kind}_${operation}.txt" \
                      "one isolated AVX2 ${lane_kind} ${operation} mechanism in wide caller"
                    forbid_pattern '(^|[[:space:]])(callq?|jmpq?).*backends__native|(^|[[:space:]])(callq?|jmpq?).*flyology_simd__(wide__)?(equal|less|greater|select_value)' \
                      "$temporary/wide_${lane_kind}_${operation}.txt" \
                      "scalar, composed, or public helper in AVX2 ${lane_kind} ${operation} caller"
                done
            done
        else
            require_count 'pcmpeqb' 2 "$temporary/wide_u8_equal.txt" \
              'two inlined SSE2 U8 equality operations in the composed Wide caller'
            require_count 'pmovmskb' 2 "$temporary/wide_u8_equal.txt" \
              'two inlined SSE2 U8 compact-mask extractions in the composed Wide caller'
            forbid_pattern '(^|[[:space:]])call' "$temporary/wide_u8_equal.txt" \
              'out-of-line helper retained in composed Wide U8 equality caller'
            for operation in less greater select; do
                require_at_most '(^|[[:space:]])call' 2 \
                  "$temporary/wide_u8_${operation}.txt" \
                  "two selected SSE2 U8 ${operation} operations in composed Wide caller"
            done
            for operation in less_equal greater_equal; do
                require_at_most '(^|[[:space:]])call' 2 \
                  "$temporary/wide_u8_${operation}.txt" \
                  "two selected SSE2 U8 ordered operations in composed Wide ${operation} caller"
                require_count 'pcmpeqb' 2 "$temporary/wide_u8_${operation}.txt" \
                  "two inlined SSE2 U8 equality operations in composed Wide ${operation} caller"
            done
            for operation in equal less greater select; do
                require_at_most '(^|[[:space:]])call' 2 \
                  "$temporary/wide_i8_${operation}.txt" \
                  "two selected SSE2 I8 ${operation} operations in composed Wide caller"
            done
            for operation in less_equal greater_equal; do
                require_at_most '(^|[[:space:]])call' 4 \
                  "$temporary/wide_i8_${operation}.txt" \
                  "four selected SSE2 I8 compare operations in composed Wide ${operation} caller"
            done
        fi
        if [ "$wide_backend" = avx2 ]; then
            require_pattern 'flyology_simd__wide__byte_avx2_leaf__add_wrap' "$temporary/wide-undefined.txt" 'wide U8 addition calls the isolated AVX2 byte implementation'
            require_pattern 'flyology_simd__wide__float_avx2_leaf__(add|subtract|multiply|divide|min_number|max_number)' "$temporary/wide-undefined.txt" 'wide floating arithmetic and extrema call isolated AVX2 implementations'
            require_pattern 'flyology_simd__wide__byte_avx2_leaf__(equal|less_than|less_equal|greater_than|greater_equal|select_value)' "$temporary/wide-undefined.txt" 'wide byte predicates call relation-specific isolated AVX2 implementations'
            forbid_pattern 'flyology_simd__wide__byte_mechanism__' "$temporary/wide-undefined.txt" 'non-AVX2 byte mechanism call retained in the public Wide caller'
        else
            require_route_or_inlined 'flyology_simd__backends__native__(u8_)?add_wrap' "$temporary/wide-undefined.txt" 'wide U8 addition calls selected 128-bit native leaves after mechanism inlining'
        fi
        if [ "$wide_backend" = composed ]; then
            require_route_or_inlined 'flyology_simd__backends__native__native_(add|subtract|multiply|divide|min_number|max_number)_(f32x4|f64x2)' "$temporary/wide-undefined.txt" 'wide floating arithmetic and extrema call selected 128-bit native leaves'
            require_at_most 'flyology_simd__backends__native__table_lookup([+-]0x[[:xdigit:]]+)?$' 4 \
              "$temporary/wide-lookup-relocs.txt" \
              'four selected 128-bit table lookups in the composed Wide lookup mechanism'
            require_at_most 'flyology_simd__backends__native__subtract_wrap([+-]0x[[:xdigit:]]+)?$' 2 \
              "$temporary/wide-lookup-relocs.txt" \
              'two selected 128-bit index adjustments in the composed Wide lookup mechanism'
            require_at_most 'flyology_simd__backends__native__bitwise_or([+-]0x[[:xdigit:]]+)?$' 2 \
              "$temporary/wide-lookup-relocs.txt" \
              'two selected 128-bit result merges in the composed Wide lookup mechanism'
            if grep -Eq 'flyology_simd__(backends__native__)?splat([+-]0x[[:xdigit:]]+)?$' \
              "$temporary/wide-lookup-relocs.txt"; then
                require_at_most 'flyology_simd__(backends__native__)?splat([+-]0x[[:xdigit:]]+)?$' 1 \
                  "$temporary/wide-lookup-relocs.txt" \
                  'one selected 128-bit 16-filled vector construction in the composed Wide lookup mechanism'
                expected_wide_lookup_symbols=4
            else
                #  The byte splat is the family one now: it fills a general
                #  register with the lane-repeat multiplier, moves it across,
                #  and broadcasts.  Which registers it picks is the
                #  allocator's business.
                require_count '(^|[[:space:]])imul[a-z]*[[:space:]]+\$0x1010101' 1 \
                  "$temporary/wide-lookup.txt" \
                  'one inlined 16-byte repeated constant in the composed Wide lookup mechanism'
                require_count '(^|[[:space:]])movd[[:space:]]+%?e[a-z0-9]+,[[:space:]]*%?xmm[0-9]+' 1 \
                  "$temporary/wide-lookup.txt" \
                  'one inlined 16-filled vector scalar transfer in the composed Wide lookup mechanism'
                require_count '(^|[[:space:]])pshufd[[:space:]]+\$(0x0*0|0),[[:space:]]*%?xmm[0-9]+,[[:space:]]*%?xmm[0-9]+' 1 \
                  "$temporary/wide-lookup.txt" \
                  'one inlined 16-filled vector broadcast in the composed Wide lookup mechanism'
                expected_wide_lookup_symbols=3
            fi
            require_at_most 'flyology_simd__backends__native__(table_lookup|subtract_wrap|bitwise_or)$|flyology_simd__(backends__native__)?splat$' \
              "$expected_wide_lookup_symbols" \
              "$temporary/wide-lookup-undefined.txt" \
              'only the intended selected 128-bit operations remain unresolved from the composed Wide lookup mechanism'
            require_at_most 'flyology_simd__' "$expected_wide_lookup_symbols" \
              "$temporary/wide-lookup-undefined.txt" \
              'only the intended library operations remain unresolved from the composed Wide lookup mechanism'
            forbid_pattern 'flyology_simd__(wide__)?table_lookup|flyology_simd__wide__native__table_lookup' \
              "$temporary/wide-lookup-undefined.txt" \
              'portable or public Wide table lookup call from the composed lookup mechanism'
        fi
        require_route_or_inlined 'flyology_simd__backends__native__bit_cast' "$temporary/wide-undefined.txt" 'wide F32 bit cast calls the selected 128-bit native leaf'
        require_route_or_inlined 'flyology_simd__backends__native__widen_(low|high)' "$temporary/wide-undefined.txt" 'wide byte widening calls selected 128-bit native leaves'
        require_route_or_inlined 'flyology_simd__backends__native__narrow_saturate' "$temporary/wide-undefined.txt" 'wide U16 narrowing calls selected 128-bit native leaves'
        require_route_or_inlined 'flyology_simd__backends__native__convert_round' "$temporary/wide-undefined.txt" 'wide integer conversion calls selected 128-bit native leaves'
        require_pattern 'flyology_simd__wide__lookup_mechanism__table_lookup_32' "$temporary/wide-undefined.txt" 'wide lookup calls the target-selected lookup mechanism'
        require_route_or_inlined 'flyology_simd__backends__native__horizontal_sum' "$temporary/wide-undefined.txt" 'wide exact byte sum calls the selected 128-bit native leaf'
        if [ "$wide_backend" = avx2 ]; then
            require_native_route 'flyology_simd__backends__native__(bit_cast|widen_low|widen_high|narrow_saturate|convert_round|horizontal_sum)|flyology_simd__wide__((byte|float)_avx2_leaf__(add_wrap|equal|equal__2|less_than|less_than__2|less_equal|less_equal__2|greater_than|greater_than__2|greater_equal|greater_equal__2|select_value|select_value__2|add|add__2|subtract|subtract__2|multiply|multiply__2|divide|divide__2|min_number|min_number__2|max_number|max_number__2)|lookup_mechanism__table_lookup_32)' 32 "$temporary/wide-undefined.txt" "$temporary/wide-probe.txt" 'only the intended native primitive classes remain unresolved from the AVX2 wide probe'
        else
            require_native_route 'flyology_simd__backends__native__((u8_)?add_wrap|native_(add|subtract|multiply|divide|min_number|max_number)_(f32x4|f64x2)|bit_cast|widen_low|widen_high|narrow_saturate|convert_round|horizontal_sum|compare_(equal|greater)(_i8x16)?|native_select_(u8|i8)x16)|flyology_simd__wide__lookup_mechanism__table_lookup_32' 23 "$temporary/wide-undefined.txt" "$temporary/wide-probe.txt" 'only the intended native primitive classes remain unresolved from the composed wide probe'
        fi
        forbid_pattern 'flyology_simd__(wide__)?(add_wrap|add|subtract|multiply|divide|min_number|max_number|bit_cast|widen_(low|high)|narrow_saturate|convert_round|table_lookup|horizontal_sum)' "$temporary/wide-undefined.txt" 'scalar or Wide primitive call from the native wide probe'
        forbid_pattern 'flyology_simd__wide__native__(add_wrap|multiply|bit_cast|widen_(low|high)|narrow_saturate|convert_round|table_lookup|horizontal_sum)' "$temporary/wide-probe.txt" 'wide native dispatcher call in caller probe'
        require_pattern 'pcmpeqb' "$temporary/algorithm.txt" 'inlined SSE2 comparison in representative loop'
        require_pattern 'pmovmskb' "$temporary/algorithm.txt" 'inlined mask extraction in representative loop'
        require_pattern 'movdqu' "$temporary/algorithm.txt" 'inlined vector load in representative loop'
        extract_symbol 'flyology_simd__algorithms__native__find_first_of' \
          "$temporary/algorithm.txt" "$temporary/find-first-of.txt"
        require_pattern 'pcmpeqb' "$temporary/find-first-of.txt" \
          'fused small-set SSE2 comparisons'
        require_pattern 'pmovmskb' "$temporary/find-first-of.txt" \
          'fused small-set SSE2 mask extraction'
        require_pattern 'movdqu' "$temporary/find-first-of.txt" \
          'fused small-set SSE2 vector load'
        extract_symbol \
          'flyology_simd__algorithms__native__find_first_difference' \
          "$temporary/algorithm.txt" "$temporary/find-first-difference.txt"
        require_pattern 'movdqu' "$temporary/find-first-difference.txt" \
          'fused two-buffer SSE2 vector loads'
        require_pattern 'pcmpeqb' "$temporary/find-first-difference.txt" \
          'fused two-buffer SSE2 byte comparison'
        require_pattern 'pmovmskb' "$temporary/find-first-difference.txt" \
          'fused two-buffer SSE2 mask extraction'
        require_pattern \
          '(^|[[:space:]])(not(l|q)?[[:space:]]|xor(w|l|q)?[[:space:]]+\$(0x(ffff|ffffffff)|-1)(,|[[:space:]]))' \
          "$temporary/find-first-difference.txt" \
          'complemented SSE2 equality mask'
        forbid_pattern \
          'call.*flyology_simd__backends__native__(load_unaligned|equal|to_bit_mask)' \
          "$temporary/find-first-difference.txt" \
          'out-of-line primitive in the Native difference loop'
        extract_symbol 'flyology_simd__algorithms__native__count_in_range' \
          "$temporary/algorithm.txt" "$temporary/count-in-range.txt"
        require_pattern 'movdqu' "$temporary/count-in-range.txt" \
          'Native range-count SSE2 vector load'
        require_at_most 'flyology_simd__backends__native__greater_equal' 1 \
          "$temporary/count-in-range.txt" \
          'one selected lower-bound comparison in Native range count'
        require_at_most 'flyology_simd__backends__native__less_equal' 1 \
          "$temporary/count-in-range.txt" \
          'one selected upper-bound comparison in Native range count'
        require_at_most 'flyology_simd__backends__native__mask_and' 1 \
          "$temporary/count-in-range.txt" \
          'one selected mask intersection in Native range count'
        #  In GNU and Apple disassembly, an instruction mnemonic is a
        #  whitespace-delimited token. Reject every VEX/EVEX mnemonic, not
        #  only the instruction classes used by the current AVX2 leaves.
        avx_instruction='(^|[[:space:]])v[a-z0-9]+([[:space:]]|$)|(^|[^[:alnum:]_])%?ymm[0-9]+([^[:alnum:]_]|$)'
        forbid_pattern "$avx_instruction" \
          "$temporary/native.txt" 'AVX instructions in the SSE2 baseline object'
        forbid_pattern "$avx_instruction" \
          "$temporary/features.txt" 'AVX instructions in feature detection'
        forbid_pattern "$avx_instruction" \
          "$temporary/baseline.txt" 'AVX instructions outside the AVX2-only object'
        if [ "$avx2" = enabled ]; then
            avx_object="$object_root/flyology_simd-algorithms-avx2_implementation.o"
            disassemble "$avx_object" >"$temporary/avx2.txt"
            nm -u "$avx_object" >"$temporary/avx2-undefined.txt"
            require_pattern 'ymm[0-9]+|vp[a-z]+' "$temporary/avx2.txt" \
              'AVX2 vectorization in the AVX2-only algorithm object'
            require_pattern 'bsf' "$temporary/avx2.txt" \
              'constant-time first-set-bit extraction in the AVX2 algorithm'
            require_pattern 'vpcmpeqb' "$temporary/avx2.txt" \
              'fused AVX2 small-set comparisons'
            require_pattern 'vpor' "$temporary/avx2.txt" \
              'fused AVX2 small-set comparison merge'
            require_pattern 'vpmovmskb' "$temporary/avx2.txt" \
              'fused AVX2 small-set mask extraction'
            require_pattern 'vzeroupper' "$temporary/avx2.txt" \
              'AVX-SSE transition cleanup in the small-set algorithm'
            require_pattern 'vmulps' "$temporary/avx2.txt" \
              'AVX2-width binary32 dot-product multiplication'
            require_pattern 'vaddps' "$temporary/avx2.txt" \
              'ordered binary32 dot-product accumulation'
            require_pattern 'vmulpd' "$temporary/avx2.txt" \
              'AVX2-width binary64 dot-product multiplication'
            require_pattern 'vaddpd' "$temporary/avx2.txt" \
              'ordered binary64 dot-product accumulation'
            require_pattern 'vextractf128' "$temporary/avx2.txt" \
              'ordered AVX2 dot-product half extraction'
            extract_symbol \
              'flyology_simd__algorithms__avx2_implementation__scale' \
              "$temporary/avx2.txt" "$temporary/avx2-f32-scale.txt"
            extract_symbol \
              'flyology_simd__algorithms__avx2_implementation__scale__2' \
              "$temporary/avx2.txt" "$temporary/avx2-f64-scale.txt"
            require_pattern 'vbroadcastss' "$temporary/avx2-f32-scale.txt" \
              'AVX2-width binary32 scale-factor broadcast'
            require_count 'vmovups' 2 "$temporary/avx2-f32-scale.txt" \
              'one AVX2-width binary32 scale load and store'
            require_pattern 'vmulps' "$temporary/avx2-f32-scale.txt" \
              'AVX2-width binary32 scaling'
            require_pattern 'vzeroupper' "$temporary/avx2-f32-scale.txt" \
              'AVX-SSE transition cleanup in binary32 scaling'
            forbid_pattern 'vaddps' "$temporary/avx2-f32-scale.txt" \
              'addition in binary32 scaling'
            require_pattern 'vbroadcastsd' "$temporary/avx2-f64-scale.txt" \
              'AVX2-width binary64 scale-factor broadcast'
            require_count 'vmovupd' 2 "$temporary/avx2-f64-scale.txt" \
              'one AVX2-width binary64 scale load and store'
            require_pattern 'vmulpd' "$temporary/avx2-f64-scale.txt" \
              'AVX2-width binary64 scaling'
            require_pattern 'vzeroupper' "$temporary/avx2-f64-scale.txt" \
              'AVX-SSE transition cleanup in binary64 scaling'
            forbid_pattern 'vaddpd' "$temporary/avx2-f64-scale.txt" \
              'addition in binary64 scaling'
            require_count \
              'flyology_simd__algorithms__native_floating__clamp$' 1 \
              "$temporary/avx2-undefined.txt" \
              'one exact selected binary32 clamp route in the AVX2 object'
            require_count \
              'flyology_simd__algorithms__native_floating__clamp__2$' 1 \
              "$temporary/avx2-undefined.txt" \
              'one exact selected binary64 clamp route in the AVX2 object'
            for entry in \
              'min_number binary32-minimum' \
              'max_number binary32-maximum' \
              'min_number__2 binary64-minimum' \
              'max_number__2 binary64-maximum'; do
                set -- $entry
                require_count \
                  "flyology_simd__algorithms__native_floating__$1$" 1 \
                  "$temporary/avx2-undefined.txt" \
                  "one exact selected $2 route in the AVX2 object"
            done
            extract_symbol \
              'flyology_simd__algorithms__avx2_implementation__axpy' \
              "$temporary/avx2.txt" "$temporary/avx2-f32-axpy.txt"
            extract_symbol \
              'flyology_simd__algorithms__avx2_implementation__axpy__2' \
              "$temporary/avx2.txt" "$temporary/avx2-f64-axpy.txt"
            require_pattern 'vbroadcastss' "$temporary/avx2-f32-axpy.txt" \
              'AVX2-width binary32 AXPY factor broadcast'
            require_count 'vmovups' 3 "$temporary/avx2-f32-axpy.txt" \
              'two AVX2-width binary32 AXPY loads and one store'
            require_pattern 'vmulps' "$temporary/avx2-f32-axpy.txt" \
              'separate AVX2-width binary32 AXPY multiplication'
            require_pattern 'vaddps' "$temporary/avx2-f32-axpy.txt" \
              'separate AVX2-width binary32 AXPY addition'
            require_pattern 'vzeroupper' "$temporary/avx2-f32-axpy.txt" \
              'AVX-SSE transition cleanup in binary32 AXPY'
            forbid_pattern 'vfmadd' "$temporary/avx2-f32-axpy.txt" \
              'fused multiply-add in exact binary32 AXPY'
            require_pattern 'vbroadcastsd' "$temporary/avx2-f64-axpy.txt" \
              'AVX2-width binary64 AXPY factor broadcast'
            require_count 'vmovupd' 3 "$temporary/avx2-f64-axpy.txt" \
              'two AVX2-width binary64 AXPY loads and one store'
            require_pattern 'vmulpd' "$temporary/avx2-f64-axpy.txt" \
              'separate AVX2-width binary64 AXPY multiplication'
            require_pattern 'vaddpd' "$temporary/avx2-f64-axpy.txt" \
              'separate AVX2-width binary64 AXPY addition'
            require_pattern 'vzeroupper' "$temporary/avx2-f64-axpy.txt" \
              'AVX-SSE transition cleanup in binary64 AXPY'
            forbid_pattern 'vfmadd' "$temporary/avx2-f64-axpy.txt" \
              'fused multiply-add in exact binary64 AXPY'
            extract_symbol \
              'flyology_simd__algorithms__avx2_implementation__count_in_range' \
              "$temporary/avx2.txt" "$temporary/avx2-count-in-range.txt"
            require_pattern 'vpmaxub' "$temporary/avx2-count-in-range.txt" \
              'AVX2 inclusive byte lower-bound classification'
            require_pattern 'vpminub' "$temporary/avx2-count-in-range.txt" \
              'AVX2 inclusive byte upper-bound classification'
            require_pattern 'vpcmpeqb' "$temporary/avx2-count-in-range.txt" \
              'AVX2 range-bound equality classification'
            require_pattern 'vpand' "$temporary/avx2-count-in-range.txt" \
              'AVX2 range-mask intersection'
            require_pattern 'vpmovmskb' \
              "$temporary/avx2-count-in-range.txt" \
              'AVX2 range-mask extraction'
            require_pattern 'vzeroupper' \
              "$temporary/avx2-count-in-range.txt" \
              'AVX-SSE transition cleanup in range count'
            extract_symbol \
              'flyology_simd__algorithms__avx2_implementation__add_saturate' \
              "$temporary/avx2.txt" "$temporary/avx2-add-saturate.txt"
            require_pattern 'vpbroadcastb' "$temporary/avx2-add-saturate.txt" \
              'AVX2-width byte Add_Saturate addend broadcast'
            require_count 'vmovdqu' 2 "$temporary/avx2-add-saturate.txt" \
              'one AVX2-width byte Add_Saturate load and store'
            require_pattern 'vpaddusb' "$temporary/avx2-add-saturate.txt" \
              'AVX2 unsigned saturating byte addition'
            require_pattern 'vzeroupper' "$temporary/avx2-add-saturate.txt" \
              'AVX-SSE transition cleanup in byte Add_Saturate'
            extract_symbol \
              'flyology_simd__algorithms__avx2_implementation__sum' \
              "$temporary/avx2.txt" "$temporary/avx2-f32-sum.txt"
            extract_symbol \
              'flyology_simd__algorithms__avx2_implementation__sum__2' \
              "$temporary/avx2.txt" "$temporary/avx2-f64-sum.txt"
            require_pattern 'vmovups' "$temporary/avx2-f32-sum.txt" \
              'AVX2-width binary32 sum load'
            require_pattern 'vaddps' "$temporary/avx2-f32-sum.txt" \
              'ordered binary32 sum accumulation'
            require_pattern 'vextractf128' "$temporary/avx2-f32-sum.txt" \
              'ordered binary32 sum half extraction'
            require_pattern 'vzeroupper' "$temporary/avx2-f32-sum.txt" \
              'AVX-SSE transition cleanup in the binary32 sum'
            forbid_pattern 'vmulps' "$temporary/avx2-f32-sum.txt" \
              'multiplication in the binary32 sum'
            require_pattern 'vmovupd' "$temporary/avx2-f64-sum.txt" \
              'AVX2-width binary64 sum load'
            require_pattern 'vaddpd' "$temporary/avx2-f64-sum.txt" \
              'ordered binary64 sum accumulation'
            require_pattern 'vextractf128' "$temporary/avx2-f64-sum.txt" \
              'ordered binary64 sum half extraction'
            require_pattern 'vzeroupper' "$temporary/avx2-f64-sum.txt" \
              'AVX-SSE transition cleanup in the binary64 sum'
            forbid_pattern 'vmulpd' "$temporary/avx2-f64-sum.txt" \
              'multiplication in the binary64 sum'
            extract_symbol \
              'flyology_simd__algorithms__avx2_implementation__find_first_difference' \
              "$temporary/avx2.txt" "$temporary/avx2-find-first-difference.txt"
            require_pattern 'vmovdqu' \
              "$temporary/avx2-find-first-difference.txt" \
              'two-buffer AVX2 vector loads'
            require_pattern 'vpcmpeqb' \
              "$temporary/avx2-find-first-difference.txt" \
              'two-buffer AVX2 byte comparison'
            require_pattern 'vpmovmskb' \
              "$temporary/avx2-find-first-difference.txt" \
              'two-buffer AVX2 mask extraction'
            require_pattern \
              '(^|[[:space:]])(not(l|q)?[[:space:]]|xor(w|l|q)?[[:space:]]+\$(0x(ffff|ffffffff)|-1)(,|[[:space:]]))' \
              "$temporary/avx2-find-first-difference.txt" \
              'complemented AVX2 equality mask'
            require_pattern 'vzeroupper' \
              "$temporary/avx2-find-first-difference.txt" \
              'AVX-SSE transition cleanup in the difference loop'
            forbid_pattern \
              'flyology_simd(__backends__native)?__(splat|load_unaligned|equal|bitwise_(and|or)|shift_right_logical|table_lookup|to_bit_mask|first_true)$' \
              "$temporary/avx2-undefined.txt" \
              'per-vector primitive relocation in the AVX2 small-set algorithm object'
        fi
        if [ "$wide_backend" = avx2 ]; then
            forbid_pattern 'flyology_simd__(__wide)?__(extract|from_lanes|permute_lanes)' "$temporary/wide-permute.txt" 'scalar or per-lane helper in AVX2 permutation object'
            for operation in add subtract multiply divide min_number max_number; do
                extract_symbol "float_avx2_leaf__${operation}" \
                  "$temporary/wide-float.txt" \
                  "$temporary/wide_float_f32_${operation}.txt"
                extract_symbol "float_avx2_leaf__${operation}__2" \
                  "$temporary/wide-float.txt" \
                  "$temporary/wide_float_f64_${operation}.txt"
            done
            require_pattern 'vaddps' "$temporary/wide_float_f32_add.txt" 'AVX2-width binary32 addition'
            require_pattern 'vsubps' "$temporary/wide_float_f32_subtract.txt" 'AVX2-width binary32 subtraction'
            require_pattern 'vmulps' "$temporary/wide_float_f32_multiply.txt" 'AVX2-width binary32 multiplication'
            require_pattern 'vdivps' "$temporary/wide_float_f32_divide.txt" 'AVX2-width binary32 division'
            require_pattern 'vaddpd' "$temporary/wide_float_f64_add.txt" 'AVX2-width binary64 addition'
            require_pattern 'vsubpd' "$temporary/wide_float_f64_subtract.txt" 'AVX2-width binary64 subtraction'
            require_pattern 'vmulpd' "$temporary/wide_float_f64_multiply.txt" 'AVX2-width binary64 multiplication'
            require_pattern 'vdivpd' "$temporary/wide_float_f64_divide.txt" 'AVX2-width binary64 division'
            for precision in f32 f64; do
                for operation in min_number max_number; do
                    require_pattern 'vpcmpgtd|vpcmpeqd' \
                      "$temporary/wide_float_${precision}_${operation}.txt" \
                      "AVX2 integer classification in ${precision} ${operation}"
                    require_pattern 'vpandn' \
                      "$temporary/wide_float_${precision}_${operation}.txt" \
                      "AVX2 bit selection in ${precision} ${operation}"
                    require_pattern 'vpor' \
                      "$temporary/wide_float_${precision}_${operation}.txt" \
                      "AVX2 result merge in ${precision} ${operation}"
                    forbid_pattern 'v(min|max)(ps|pd)|vcmp(ps|pd)' \
                      "$temporary/wide_float_${precision}_${operation}.txt" \
                      "floating compare or min/max in exact ${precision} ${operation}"
                done
            done
            for leaf in "$temporary"/wide_float_*.txt; do
                require_leaf_instruction 'vzeroupper' 1 "$leaf" \
                  'one AVX-SSE transition cleanup in each Wide floating leaf'
                forbid_pattern '(^|[[:space:]])(call|jmp)[[:space:]]|flyology_simd__backends__native|flyology_simd__wide__(native|add|subtract|multiply|divide|min_number|max_number)' \
                  "$leaf" 'scalar, composed, or out-of-line call in AVX2 floating leaf'
            done
            forbid_pattern 'flyology_simd__backends__native|flyology_simd__wide__(native|add|subtract|multiply|divide|min_number|max_number)' \
              "$temporary/wide-float-undefined.txt" \
              'scalar, composed, or public dispatcher call from AVX2 floating implementation'
            extract_symbol 'byte_avx2_leaf__add_wrap' "$temporary/wide-byte.txt" "$temporary/wide_byte_u8_add.txt"
            extract_symbol 'byte_avx2_leaf__add_wrap__2' "$temporary/wide-byte.txt" "$temporary/wide_byte_i8_add.txt"
            extract_symbol 'byte_avx2_leaf__subtract_wrap' "$temporary/wide-byte.txt" "$temporary/wide_byte_u8_subtract.txt"
            extract_symbol 'byte_avx2_leaf__subtract_wrap__2' "$temporary/wide-byte.txt" "$temporary/wide_byte_i8_subtract.txt"
            extract_symbol 'byte_avx2_leaf__multiply_wrap' "$temporary/wide-byte.txt" "$temporary/wide_byte_u8_multiply.txt"
            extract_symbol 'byte_avx2_leaf__multiply_wrap__2' "$temporary/wide-byte.txt" "$temporary/wide_byte_i8_multiply.txt"
            extract_symbol 'byte_avx2_leaf__add_saturate' "$temporary/wide-byte.txt" "$temporary/wide_byte_u8_add_sat.txt"
            extract_symbol 'byte_avx2_leaf__add_saturate__2' "$temporary/wide-byte.txt" "$temporary/wide_byte_i8_add_sat.txt"
            extract_symbol 'byte_avx2_leaf__subtract_saturate' "$temporary/wide-byte.txt" "$temporary/wide_byte_u8_sub_sat.txt"
            extract_symbol 'byte_avx2_leaf__subtract_saturate__2' "$temporary/wide-byte.txt" "$temporary/wide_byte_i8_sub_sat.txt"
            extract_symbol 'byte_avx2_leaf__bitwise_and' "$temporary/wide-byte.txt" "$temporary/wide_byte_u8_and.txt"
            extract_symbol 'byte_avx2_leaf__bitwise_and__2' "$temporary/wide-byte.txt" "$temporary/wide_byte_i8_and.txt"
            extract_symbol 'byte_avx2_leaf__bitwise_or' "$temporary/wide-byte.txt" "$temporary/wide_byte_u8_or.txt"
            extract_symbol 'byte_avx2_leaf__bitwise_or__2' "$temporary/wide-byte.txt" "$temporary/wide_byte_i8_or.txt"
            extract_symbol 'byte_avx2_leaf__bitwise_xor' "$temporary/wide-byte.txt" "$temporary/wide_byte_u8_xor.txt"
            extract_symbol 'byte_avx2_leaf__bitwise_xor__2' "$temporary/wide-byte.txt" "$temporary/wide_byte_i8_xor.txt"
            extract_symbol 'byte_avx2_leaf__bitwise_not' "$temporary/wide-byte.txt" "$temporary/wide_byte_u8_not.txt"
            extract_symbol 'byte_avx2_leaf__bitwise_not__2' "$temporary/wide-byte.txt" "$temporary/wide_byte_i8_not.txt"
            extract_symbol 'byte_avx2_leaf__min' "$temporary/wide-byte.txt" "$temporary/wide_byte_u8_min.txt"
            extract_symbol 'byte_avx2_leaf__min__2' "$temporary/wide-byte.txt" "$temporary/wide_byte_i8_min.txt"
            extract_symbol 'byte_avx2_leaf__max' "$temporary/wide-byte.txt" "$temporary/wide_byte_u8_max.txt"
            extract_symbol 'byte_avx2_leaf__max__2' "$temporary/wide-byte.txt" "$temporary/wide_byte_i8_max.txt"
            extract_symbol 'byte_avx2_leaf__equal' "$temporary/wide-byte.txt" "$temporary/wide_byte_u8_equal.txt"
            extract_symbol 'byte_avx2_leaf__equal__2' "$temporary/wide-byte.txt" "$temporary/wide_byte_i8_equal.txt"
            extract_symbol 'byte_avx2_leaf__greater_than' "$temporary/wide-byte.txt" "$temporary/wide_byte_u8_greater.txt"
            extract_symbol 'byte_avx2_leaf__greater_than__2' "$temporary/wide-byte.txt" "$temporary/wide_byte_i8_greater.txt"
            extract_symbol 'byte_avx2_leaf__less_than' "$temporary/wide-byte.txt" "$temporary/wide_byte_u8_less.txt"
            extract_symbol 'byte_avx2_leaf__less_than__2' "$temporary/wide-byte.txt" "$temporary/wide_byte_i8_less.txt"
            extract_symbol 'byte_avx2_leaf__less_equal' "$temporary/wide-byte.txt" "$temporary/wide_byte_u8_less_equal.txt"
            extract_symbol 'byte_avx2_leaf__less_equal__2' "$temporary/wide-byte.txt" "$temporary/wide_byte_i8_less_equal.txt"
            extract_symbol 'byte_avx2_leaf__greater_equal' "$temporary/wide-byte.txt" "$temporary/wide_byte_u8_greater_equal.txt"
            extract_symbol 'byte_avx2_leaf__greater_equal__2' "$temporary/wide-byte.txt" "$temporary/wide_byte_i8_greater_equal.txt"
            extract_symbol 'byte_avx2_leaf__select_value' "$temporary/wide-byte.txt" "$temporary/wide_byte_u8_select.txt"
            extract_symbol 'byte_avx2_leaf__select_value__2' "$temporary/wide-byte.txt" "$temporary/wide_byte_i8_select.txt"
            for signedness in u8 i8; do
                add_leaf="$temporary/wide_byte_${signedness}_add.txt"
                subtract_leaf="$temporary/wide_byte_${signedness}_subtract.txt"
                multiply_leaf="$temporary/wide_byte_${signedness}_multiply.txt"
                for leaf in "$add_leaf" "$subtract_leaf" "$multiply_leaf"; do
                    require_leaf_instruction 'vmovdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%ymm0' 2 \
                      "$leaf" "left-operand and return-copy loads in AVX2 ${signedness} wrapping leaf"
                    require_leaf_instruction 'vmovdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%ymm1' 1 \
                      "$leaf" "one right-operand load in AVX2 ${signedness} wrapping leaf"
                    require_leaf_instruction 'vmovdqu[[:space:]]+%ymm0,[[:space:]]*[^,]*\([^)]*\)' 2 \
                      "$leaf" "assembly-result and return-value stores in AVX2 ${signedness} wrapping leaf"
                    require_leaf_instruction 'vmovdqu[[:space:]]+\(%rsi\),[[:space:]]*%ymm0' 1 \
                      "$leaf" "left ABI operand in AVX2 ${signedness} wrapping leaf"
                    require_leaf_instruction 'vmovdqu[[:space:]]+\(%rcx\),[[:space:]]*%ymm1' 1 \
                      "$leaf" "right ABI operand in AVX2 ${signedness} wrapping leaf"
                    require_leaf_instruction 'vmovdqu[[:space:]]+%ymm0,[[:space:]]*\(%rdx\)' 1 \
                      "$leaf" "assembly result destination in AVX2 ${signedness} wrapping leaf"
                    forbid_pattern '(^|[[:space:]])(callq?|j[a-z]+)[[:space:]]' \
                      "$leaf" "branch or helper in AVX2 ${signedness} wrapping leaf"
                done
                require_count 'vpaddb[[:space:]]+%ymm1,[[:space:]]*%ymm0,[[:space:]]*%ymm0' 1 \
                  "$add_leaf" "one exact AVX2 ${signedness} wrapping byte addition"
                forbid_pattern 'vpsubb|vpmullw' "$add_leaf" \
                  "unrelated wrapping operation in AVX2 ${signedness} addition leaf"
                require_count 'vpsubb[[:space:]]+%ymm1,[[:space:]]*%ymm0,[[:space:]]*%ymm0' 1 \
                  "$subtract_leaf" "one exact AVX2 ${signedness} wrapping byte subtraction"
                forbid_pattern 'vpaddb|vpmullw' "$subtract_leaf" \
                  "unrelated wrapping operation in AVX2 ${signedness} subtraction leaf"
                require_count 'vpcmpeqd' 1 "$multiply_leaf" \
                  "one AVX2 ${signedness} low-byte mask source"
                require_count 'vpsrlw[[:space:]]+\$(0x0*8|8),' 3 "$multiply_leaf" \
                  "three shift-by-eight extractions in AVX2 ${signedness} multiplication"
                require_count 'vpand' 3 "$multiply_leaf" \
                  "three low-byte masks in AVX2 ${signedness} multiplication"
                require_count 'vpmullw' 2 "$multiply_leaf" \
                  "two even/odd word products in AVX2 ${signedness} multiplication"
                require_count 'vpsllw[[:space:]]+\$(0x0*8|8),' 1 "$multiply_leaf" \
                  "one shift-by-eight placement in AVX2 ${signedness} multiplication"
                require_count 'vpor' 1 "$multiply_leaf" \
                  "one even/odd product merge in AVX2 ${signedness} multiplication"
                forbid_pattern 'vpaddb|vpsubb' "$multiply_leaf" \
                  "unrelated wrapping operation in AVX2 ${signedness} multiplication leaf"
            done
            require_pattern 'vpaddusb' "$temporary/wide_byte_u8_add_sat.txt" 'AVX2 unsigned saturating byte addition'
            require_pattern 'vpaddsb' "$temporary/wide_byte_i8_add_sat.txt" 'AVX2 signed saturating byte addition'
            require_pattern 'vpsubusb' "$temporary/wide_byte_u8_sub_sat.txt" 'AVX2 unsigned saturating byte subtraction'
            require_pattern 'vpsubsb' "$temporary/wide_byte_i8_sub_sat.txt" 'AVX2 signed saturating byte subtraction'
            for signedness in u8 i8; do
                for operation in and or xor; do
                    leaf="$temporary/wide_byte_${signedness}_${operation}.txt"
                    require_leaf_instruction 'vmovdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%ymm0' 2 \
                      "$leaf" "left-operand and return-copy loads in AVX2 ${signedness} bitwise ${operation} leaf"
                    require_leaf_instruction 'vmovdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%ymm1' 1 \
                      "$leaf" "one right-operand load in AVX2 ${signedness} bitwise ${operation} leaf"
                    require_leaf_instruction 'vmovdqu[[:space:]]+%ymm0,[[:space:]]*[^,]*\([^)]*\)' 2 \
                      "$leaf" "assembly-result and return-value stores in AVX2 ${signedness} bitwise ${operation} leaf"
                    require_leaf_instruction 'vmovdqu[[:space:]]+\(%rsi\),[[:space:]]*%ymm0' 1 \
                      "$leaf" "left ABI operand in AVX2 ${signedness} bitwise ${operation} leaf"
                    require_leaf_instruction 'vmovdqu[[:space:]]+\(%rcx\),[[:space:]]*%ymm1' 1 \
                      "$leaf" "right ABI operand in AVX2 ${signedness} bitwise ${operation} leaf"
                    require_leaf_instruction 'vmovdqu[[:space:]]+%ymm0,[[:space:]]*\(%rdx\)' 1 \
                      "$leaf" "assembly result destination in AVX2 ${signedness} bitwise ${operation} leaf"
                    forbid_pattern '(^|[[:space:]])(callq?|j[a-z]+)[[:space:]]' \
                      "$leaf" "branch or helper in AVX2 ${signedness} bitwise ${operation} leaf"
                done
                require_count 'vpand[[:space:]]+%ymm1,[[:space:]]*%ymm0,[[:space:]]*%ymm0' 1 \
                  "$temporary/wide_byte_${signedness}_and.txt" \
                  "one exact AVX2 ${signedness} bitwise conjunction"
                require_count '(^|[[:space:]])vpand[[:space:]]' 1 \
                  "$temporary/wide_byte_${signedness}_and.txt" \
                  "only one AVX2 ${signedness} conjunction instruction"
                forbid_pattern 'vpandn|vpor|vpxor|vpcmpeqd' "$temporary/wide_byte_${signedness}_and.txt" \
                  "unrelated bitwise operation in AVX2 ${signedness} conjunction leaf"
                require_count 'vpor[[:space:]]+%ymm1,[[:space:]]*%ymm0,[[:space:]]*%ymm0' 1 \
                  "$temporary/wide_byte_${signedness}_or.txt" \
                  "one exact AVX2 ${signedness} bitwise disjunction"
                require_count '(^|[[:space:]])vpor[[:space:]]' 1 \
                  "$temporary/wide_byte_${signedness}_or.txt" \
                  "only one AVX2 ${signedness} disjunction instruction"
                forbid_pattern 'vpand|vpxor|vpcmpeqd' "$temporary/wide_byte_${signedness}_or.txt" \
                  "unrelated bitwise operation in AVX2 ${signedness} disjunction leaf"
                require_count 'vpxor[[:space:]]+%ymm1,[[:space:]]*%ymm0,[[:space:]]*%ymm0' 1 \
                  "$temporary/wide_byte_${signedness}_xor.txt" \
                  "one exact AVX2 ${signedness} bitwise exclusive disjunction"
                require_count '(^|[[:space:]])vpxor[[:space:]]' 1 \
                  "$temporary/wide_byte_${signedness}_xor.txt" \
                  "only one AVX2 ${signedness} exclusive-disjunction instruction"
                forbid_pattern 'vpand|vpor|vpcmpeqd' "$temporary/wide_byte_${signedness}_xor.txt" \
                  "unrelated bitwise operation in AVX2 ${signedness} exclusive-disjunction leaf"

                leaf="$temporary/wide_byte_${signedness}_not.txt"
                require_leaf_instruction 'vmovdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%ymm0' 2 \
                  "$leaf" "operand and return-copy loads in AVX2 ${signedness} complement leaf"
                require_leaf_instruction 'vmovdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%ymm1' 0 \
                  "$leaf" "no second memory operand in AVX2 ${signedness} complement leaf"
                require_leaf_instruction 'vmovdqu[[:space:]]+%ymm0,[[:space:]]*[^,]*\([^)]*\)' 2 \
                  "$leaf" "assembly-result and return-value stores in AVX2 ${signedness} complement leaf"
                require_leaf_instruction 'vmovdqu[[:space:]]+\(%rsi\),[[:space:]]*%ymm0' 1 \
                  "$leaf" "ABI operand in AVX2 ${signedness} complement leaf"
                require_leaf_instruction 'vmovdqu[[:space:]]+%ymm0,[[:space:]]*\(%rdx\)' 1 \
                  "$leaf" "assembly result destination in AVX2 ${signedness} complement leaf"
                require_leaf_instruction 'vpcmpeqd[[:space:]]+%ymm1,[[:space:]]*%ymm1,[[:space:]]*%ymm1' 1 \
                  "$leaf" "one all-one mask construction in AVX2 ${signedness} complement leaf"
                require_leaf_instruction 'vpxor[[:space:]]+%ymm1,[[:space:]]*%ymm0,[[:space:]]*%ymm0' 1 \
                  "$leaf" "one exact AVX2 ${signedness} bitwise complement"
                require_leaf_instruction '(^|[[:space:]])vpcmpeqd[[:space:]]' 1 \
                  "$leaf" "only one all-one mask construction in AVX2 ${signedness} complement leaf"
                require_leaf_instruction '(^|[[:space:]])vpxor[[:space:]]' 1 \
                  "$leaf" "only one AVX2 ${signedness} complement instruction"
                forbid_pattern 'vpand|vpor|(^|[[:space:]])(callq?|j[a-z]+)[[:space:]]' \
                  "$leaf" "unrelated bitwise operation, branch, or helper in AVX2 ${signedness} complement leaf"
            done
            for signedness in u8 i8; do
                for operation in min max; do
                    leaf="$temporary/wide_byte_${signedness}_${operation}.txt"
                    require_leaf_instruction 'vmovdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%ymm0' 2 \
                      "$leaf" "left-operand and return-copy loads in AVX2 ${signedness} ${operation} leaf"
                    require_leaf_instruction 'vmovdqu[[:space:]]+[^,]*\([^)]*\),[[:space:]]*%ymm1' 1 \
                      "$leaf" "one right-operand load in AVX2 ${signedness} ${operation} leaf"
                    require_leaf_instruction 'vmovdqu[[:space:]]+%ymm0,[[:space:]]*[^,]*\([^)]*\)' 2 \
                      "$leaf" "assembly-result and return-value stores in AVX2 ${signedness} ${operation} leaf"
                    require_leaf_instruction 'vmovdqu[[:space:]]+\(%rsi\),[[:space:]]*%ymm0' 1 \
                      "$leaf" "left ABI operand in AVX2 ${signedness} ${operation} leaf"
                    require_leaf_instruction 'vmovdqu[[:space:]]+\(%rcx\),[[:space:]]*%ymm1' 1 \
                      "$leaf" "right ABI operand in AVX2 ${signedness} ${operation} leaf"
                    require_leaf_instruction 'vmovdqu[[:space:]]+%ymm0,[[:space:]]*\(%rdx\)' 1 \
                      "$leaf" "assembly result destination in AVX2 ${signedness} ${operation} leaf"
                    require_leaf_instruction 'vmovdqu[[:space:]]+%ymm0,[[:space:]]*\(%rdi\)' 1 \
                      "$leaf" "hidden-result return store in AVX2 ${signedness} ${operation} leaf"
                    require_leaf_instruction 'movq?[[:space:]]+%rdi,[[:space:]]*%rax' 1 \
                      "$leaf" "hidden-result return address in AVX2 ${signedness} ${operation} leaf"
                    require_leaf_instruction 'movq?[[:space:]]+%rdx,[[:space:]]*%rcx' 1 \
                      "$leaf" "right-operand ABI routing in AVX2 ${signedness} ${operation} leaf"
                    case "$signedness:$operation" in
                        u8:min) instruction=vpminub ;;
                        i8:min) instruction=vpminsb ;;
                        u8:max) instruction=vpmaxub ;;
                        i8:max) instruction=vpmaxsb ;;
                    esac
                    require_leaf_instruction "${instruction}[[:space:]]+%ymm1,[[:space:]]*%ymm0,[[:space:]]*%ymm0" 1 \
                      "$leaf" "one exact AVX2 ${signedness} ${operation}"
                    require_leaf_instruction "(^|[[:space:]])${instruction}[[:space:]]" 1 \
                      "$leaf" "only one AVX2 ${signedness} ${operation} instruction"
                    require_leaf_instruction 'vzeroupper' 2 "$leaf" \
                      "two AVX-SSE transition cleanups in AVX2 ${signedness} ${operation} leaf"
                    case "$instruction" in
                        vpminub) unrelated='vpminsb|vpmaxub|vpmaxsb' ;;
                        vpminsb) unrelated='vpminub|vpmaxub|vpmaxsb' ;;
                        vpmaxub) unrelated='vpminub|vpminsb|vpmaxsb' ;;
                        vpmaxsb) unrelated='vpminub|vpminsb|vpmaxub' ;;
                    esac
                    forbid_pattern "$unrelated|(^|[[:space:]])(callq?|j[a-z]+)[[:space:]]" \
                      "$leaf" "unrelated extrema operation, branch, or helper in AVX2 ${signedness} ${operation} leaf"
                done
            done
            require_pattern 'vpcmpeqb' "$temporary/wide_byte_u8_equal.txt" 'AVX2 unsigned byte equality'
            require_pattern 'vpcmpeqb' "$temporary/wide_byte_i8_equal.txt" 'AVX2 signed byte equality'
            require_pattern 'vpmovmskb' "$temporary/wide_byte_u8_equal.txt" 'AVX2 unsigned compact equality mask'
            require_pattern 'vpmovmskb' "$temporary/wide_byte_i8_equal.txt" 'AVX2 signed compact equality mask'
            require_pattern 'vpcmpgtb' "$temporary/wide_byte_u8_greater.txt" 'AVX2 unsigned byte ordering compare'
            require_pattern 'vpcmpgtb' "$temporary/wide_byte_i8_greater.txt" 'AVX2 signed byte ordering compare'
            require_count 'vpxor' 2 "$temporary/wide_byte_u8_greater.txt" 'two AVX2 unsigned sign-bit bias transforms'
            require_pattern 'vpmovmskb' "$temporary/wide_byte_u8_greater.txt" 'AVX2 unsigned compact ordered mask'
            require_pattern 'vpmovmskb' "$temporary/wide_byte_i8_greater.txt" 'AVX2 signed compact ordered mask'
            for relation in less less_equal greater_equal; do
                require_pattern 'vpcmpgtb' "$temporary/wide_byte_u8_${relation}.txt" \
                  "AVX2 unsigned byte compare in ${relation} relation leaf"
                require_pattern 'vpcmpgtb' "$temporary/wide_byte_i8_${relation}.txt" \
                  "AVX2 signed byte compare in ${relation} relation leaf"
                require_pattern 'vpmovmskb' "$temporary/wide_byte_u8_${relation}.txt" \
                  "AVX2 unsigned compact mask in ${relation} relation leaf"
                require_pattern 'vpmovmskb' "$temporary/wide_byte_i8_${relation}.txt" \
                  "AVX2 signed compact mask in ${relation} relation leaf"
                require_count 'vpxor' 2 "$temporary/wide_byte_u8_${relation}.txt" \
                  "two AVX2 unsigned sign-bit bias transforms in ${relation} relation leaf"
            done
            for relation in less_equal greater_equal; do
                require_pattern '(^|[[:space:]])not(l|q)?[[:space:]]' \
                  "$temporary/wide_byte_u8_${relation}.txt" \
                  "compact-mask complement in unsigned ${relation} relation leaf"
                require_pattern '(^|[[:space:]])not(l|q)?[[:space:]]' \
                  "$temporary/wide_byte_i8_${relation}.txt" \
                  "compact-mask complement in signed ${relation} relation leaf"
            done
            for leaf in "$temporary/wide_byte_u8_select.txt" "$temporary/wide_byte_i8_select.txt"; do
                require_pattern 'vpbroadcastd' "$leaf" 'AVX2 compact-mask broadcast for selection'
                require_pattern 'vpshufb' "$leaf" 'AVX2 compact-mask byte expansion for selection'
                require_pattern 'vpcmpeqb' "$leaf" 'AVX2 all-bits lane mask construction for selection'
                require_pattern 'vpandn' "$leaf" 'AVX2 false-lane selection'
                require_pattern 'vpor' "$leaf" 'AVX2 selected-lane merge'
            done
            for leaf in "$temporary"/wide_byte_*.txt; do
                require_pattern 'vzeroupper' "$leaf" 'AVX-SSE transition cleanup in each Wide byte leaf'
                require_final_avx_instruction 'vzeroupper' "$leaf" \
                  'vzeroupper is the final AVX instruction in each Wide byte leaf'
            done
            forbid_pattern 'flyology_simd__backends__native|flyology_simd__wide__(native|add_wrap|subtract_wrap|multiply_wrap|add_saturate|subtract_saturate|bitwise_|min|max|equal|less|greater|select_value)' "$temporary/wide-byte-undefined.txt" 'scalar, composed, or public dispatcher call from the AVX2 byte implementation'
            extract_symbol 'table_lookup_32' "$temporary/wide-lookup.txt" "$temporary/wide_lookup_leaf.txt"
            require_pattern 'vpshufb' "$temporary/wide_lookup_leaf.txt" \
              'AVX2 lane-local byte selection in the Wide lookup leaf'
            require_pattern 'vperm2i128' "$temporary/wide_lookup_leaf.txt" \
              'AVX2 cross-half table selection in the Wide lookup leaf'
            require_pattern 'vpsubusb' "$temporary/wide_lookup_leaf.txt" \
              'AVX2 out-of-range index rejection in the Wide lookup leaf'
            require_pattern 'vzeroupper' "$temporary/wide_lookup_leaf.txt" \
              'AVX-SSE transition cleanup in the Wide lookup leaf'
            require_final_avx_instruction 'vzeroupper' "$temporary/wide_lookup_leaf.txt" \
              'vzeroupper is the final AVX instruction in the Wide lookup leaf'
        fi
        ;;
    *)
        echo "unsupported code-generation architecture: $architecture" >&2
        exit 2
        ;;
esac

if nm -u "$algorithm_object" 2>/dev/null | grep -Eq '[_ ]flyology_simd__equal$'; then
    echo "representative native algorithm calls the scalar equality helper" >&2
    exit 1
fi

if nm -u "$algorithm_object" 2>/dev/null | grep -Eq \
  'flyology_simd__backends__native__(splat|load_unaligned|equal|bitwise_and|bitwise_or|shift_right_logical|table_lookup|to_bit_mask|equal_bits|neon_bitwise_and|u8_and)$'; then
    echo "representative native algorithm retains an out-of-line backend primitive" >&2
    exit 1
fi

echo "code-generation checks passed: architecture=$architecture avx2=$avx2 wide_backend=$wide_backend"
