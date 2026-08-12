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
feature_object="$object_root/flyology_simd-features.o"
slide_probe_object="$probe_root/slide_codegen_probe.o"
permute_probe_object="$probe_root/permute_codegen_probe.o"
wide_probe_object="$probe_root/wide_codegen_probe.o"
wide_reduction_probe_object="$probe_root/wide_reduction_codegen_probe.o"
wide_float_reduction_probe_object="$probe_root/wide_float_reduction_codegen_probe.o"
wide_byte_object="$object_root/flyology_simd-wide-byte_avx2_leaf.o"
wide_lookup_object="$object_root/flyology_simd-wide-lookup_mechanism.o"
wide_permute_object="$object_root/flyology_simd-wide-permute_mechanism.o"

disassemble() {
    if command -v otool >/dev/null 2>&1; then
        otool -tvV "$1"
    else
        objdump -d "$1"
    fi
}

disassemble "$native_object" >"$temporary/native.txt"
disassemble "$algorithm_object" >"$temporary/algorithm.txt"
disassemble "$feature_object" >"$temporary/features.txt"
disassemble "$slide_probe_object" >"$temporary/slide-probe.txt"
disassemble "$permute_probe_object" >"$temporary/permute-probe.txt"
disassemble "$wide_probe_object" >"$temporary/wide-probe.txt"
disassemble "$wide_reduction_probe_object" >"$temporary/wide-reduction-probe.txt"
disassemble "$wide_float_reduction_probe_object" >"$temporary/wide-float-reduction-probe.txt"
objdump -r "$wide_reduction_probe_object" >"$temporary/wide-reduction-relocs.txt"
if [ -f "$wide_byte_object" ]; then
    disassemble "$wide_byte_object" >"$temporary/wide-byte.txt"
    nm -u "$wide_byte_object" >"$temporary/wide-byte-undefined.txt"
else
    : >"$temporary/wide-byte.txt"
    : >"$temporary/wide-byte-undefined.txt"
fi
disassemble "$wide_lookup_object" >"$temporary/wide-lookup.txt"
disassemble "$wide_permute_object" >"$temporary/wide-permute.txt"
nm -u "$wide_probe_object" >"$temporary/wide-undefined.txt"
nm -u "$wide_reduction_probe_object" >"$temporary/wide-reduction-undefined.txt"
nm -u "$wide_float_reduction_probe_object" >"$temporary/wide-float-reduction-undefined.txt"

require_pattern() {
    pattern=$1
    file=$2
    description=$3
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

require_count() {
    pattern=$1
    expected=$2
    file=$3
    description=$4
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

extract_symbol() {
    symbol=$1
    file=$2
    output=$3
    awk -v symbol="$symbol" '
        BEGIN { found = 0 }
        {
            lowered = tolower($0)
            if (!found && index(lowered, symbol) > 0 && $0 ~ /:$/) {
                found = 1
                print
                next
            }
            if (found && ($0 ~ /^[[:xdigit:]]+[[:space:]]+<[^>]+>:/ || $0 ~ /^_[A-Za-z0-9_$.]+:$/)) {
                exit
            }
            if (found) print
        }
        END { if (!found) exit 1 }
    ' "$file" >"$output"
}

require_count 'backends__native__reduce_add_wrap' 2 \
  "$temporary/wide-reduction-relocs.txt" \
  'two selected 128-bit wrapping-sum reductions in the Wide caller'
require_count 'backends__native__reduce_min' 2 \
  "$temporary/wide-reduction-relocs.txt" \
  'two selected 128-bit minimum reductions in the Wide caller'
require_count 'backends__native__reduce_max' 2 \
  "$temporary/wide-reduction-relocs.txt" \
  'two selected 128-bit maximum reductions in the Wide caller'
require_pattern 'backends__native__(neon_)?add_wrap' \
  "$temporary/wide-reduction-relocs.txt" \
  'selected 128-bit wrapping combine in the Wide reduction caller'
require_pattern 'backends__native__min' "$temporary/wide-reduction-relocs.txt" \
  'selected 128-bit minimum combine in the Wide reduction caller'
require_pattern 'backends__native__max' "$temporary/wide-reduction-relocs.txt" \
  'selected 128-bit maximum combine in the Wide reduction caller'
require_count 'backends__native__extract' 3 \
  "$temporary/wide-reduction-relocs.txt" \
  'selected lane-zero extraction for all Wide reduction probes'
forbid_pattern 'flyology_simd__wide__(native__)?reduce_|flyology_simd__reduce_' \
  "$temporary/wide-reduction-undefined.txt" \
  'Wide dispatcher or portable scalar reduction retained in caller probe'

case "$architecture" in
    aarch64)
        extract_symbol 'wide_float_reduction_codegen_probe__f32_reduce_add' \
          "$temporary/wide-float-reduction-probe.txt" \
          "$temporary/wide-f32-reduce-add.txt"
        extract_symbol 'wide_float_reduction_codegen_probe__f32_reduce_min_number' \
          "$temporary/wide-float-reduction-probe.txt" \
          "$temporary/wide-f32-reduce-min.txt"
        extract_symbol 'wide_float_reduction_codegen_probe__f64_reduce_max_number' \
          "$temporary/wide-float-reduction-probe.txt" \
          "$temporary/wide-f64-reduce-max.txt"
        require_count 'fadd[[:space:]]+s' 8 "$temporary/wide-f32-reduce-add.txt" \
          'eight ordered scalar F32 additions in the Wide reduction caller'
        require_count 'fminnm[[:space:]]+s' 7 "$temporary/wide-f32-reduce-min.txt" \
          'seven ordered scalar F32 minimum-number steps in the Wide reduction caller'
        require_count 'fmaxnm[[:space:]]+d' 3 "$temporary/wide-f64-reduce-max.txt" \
          'three ordered scalar F64 maximum-number steps in the Wide reduction caller'
        for floating_reduction_probe in \
          wide-f32-reduce-add wide-f32-reduce-min wide-f64-reduce-max; do
            require_count 'ldr[[:space:]]+q' 2 \
              "$temporary/${floating_reduction_probe}.txt" \
              "two Wide input-half loads in ${floating_reduction_probe}"
            forbid_pattern '(^|[[:space:]])bl[[:space:]]|flyology_simd__(wide__)?reduce_' \
              "$temporary/${floating_reduction_probe}.txt" \
              "out-of-line or portable reduction in ${floating_reduction_probe}"
        done
        require_pattern 'cmeq' "$temporary/native.txt" 'NEON byte comparison'
        require_pattern 'add.*16b' "$temporary/native.txt" 'NEON wrapping byte add'
        require_pattern 'sub.*16b' "$temporary/native.txt" 'NEON wrapping byte subtract'
        require_pattern 'uqadd' "$temporary/native.txt" 'NEON saturating byte add'
        require_pattern 'uqsub' "$temporary/native.txt" 'NEON saturating byte subtract'
        require_pattern 'orr.*16b' "$temporary/native.txt" 'NEON byte OR'
        require_pattern 'eor.*16b' "$temporary/native.txt" 'NEON byte XOR'
        require_pattern 'mvn.*16b' "$temporary/native.txt" 'NEON byte complement'
        require_pattern 'ushl.*16b' "$temporary/native.txt" 'NEON defined byte shifts'
        require_pattern 'cmhi.*16b' "$temporary/native.txt" 'NEON unsigned ordered comparison'
        require_pattern 'cmhs.*16b' "$temporary/native.txt" 'NEON unsigned inclusive comparison'
        require_pattern 'bsl.*16b' "$temporary/native.txt" 'NEON masked selection'
        require_pattern 'rev64.*16b' "$temporary/native.txt" 'NEON byte reversal'
        require_pattern 'zip1.*16b' "$temporary/native.txt" 'NEON low interleave'
        require_pattern 'zip2.*16b' "$temporary/native.txt" 'NEON high interleave'
        require_pattern 'uzp1.*16b' "$temporary/native.txt" 'NEON even deinterleave'
        require_pattern 'uzp2.*16b' "$temporary/native.txt" 'NEON odd deinterleave'
        require_pattern 'uminv.*16b' "$temporary/native.txt" 'NEON unsigned byte minimum reduction'
        require_pattern 'umaxv.*16b' "$temporary/native.txt" 'NEON unsigned byte maximum reduction'
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
        require_pattern 'dup.*2d.*v0.*\[1\]' "$temporary/reduce_min_i64.txt" 'NEON signed-64 reduction lane broadcast'
        require_pattern 'cmgt.*2d' "$temporary/reduce_min_i64.txt" 'NEON signed-64 minimum comparison'
        require_pattern 'bit.*16b' "$temporary/reduce_min_i64.txt" 'NEON signed-64 minimum selection'
        require_pattern 'dup.*2d.*v0.*\[1\]' "$temporary/reduce_max_u64.txt" 'NEON unsigned-64 reduction lane broadcast'
        require_pattern 'cmhi.*2d' "$temporary/reduce_max_u64.txt" 'NEON unsigned-64 maximum comparison'
        require_pattern 'bif.*16b' "$temporary/reduce_max_u64.txt" 'NEON unsigned-64 maximum selection'
        extract_symbol 'native_table_lookup_u8x16' "$temporary/native.txt" "$temporary/table_lookup.txt"
        require_pattern 'tbl.*16b' "$temporary/table_lookup.txt" 'NEON byte-table lookup'
        for lane_kind in u8 i8 u16 i16 u32 i32 f32 u64 i64 f64; do
            for operation in compress expand; do
                extract_symbol "permute_codegen_probe__${lane_kind}_${operation}" "$temporary/permute-probe.txt" "$temporary/${lane_kind}_${operation}.txt"
                require_pattern 'tbl.*16b' "$temporary/${lane_kind}_${operation}.txt" "inlined NEON ${lane_kind} ${operation} caller"
            done
        done
        forbid_pattern 'flyology_simd__backends__native__(compress|expand)' "$temporary/permute-probe.txt" 'compression backend call in caller probe'
        for lane_kind in u8 u16 f32 f64; do
            extract_symbol "permute_codegen_probe__${lane_kind}_permute" "$temporary/permute-probe.txt" "$temporary/permute_${lane_kind}.txt"
            require_pattern 'tbl.*16b' "$temporary/permute_${lane_kind}.txt" "NEON ${lane_kind} public lane permutation"
            extract_symbol "permute_codegen_probe__${lane_kind}_permute_2" "$temporary/permute-probe.txt" "$temporary/permute_2_${lane_kind}.txt"
            require_pattern 'tbl(\.16b)?[[:space:]]+v[0-9]+,.*\{[[:space:]]*v[0-9]+,[[:space:]]*v[0-9]+[[:space:]]*\},[[:space:]]*v[0-9]+' "$temporary/permute_2_${lane_kind}.txt" "NEON ${lane_kind} public two-source lane permutation"
        done
        forbid_pattern 'flyology_simd__backends__native__permute_lanes' "$temporary/permute-probe.txt" 'lane-permutation backend call in caller probe'
        extract_symbol 'wide_codegen_probe__u8_add' "$temporary/wide-probe.txt" "$temporary/wide_u8_add.txt"
        extract_symbol 'wide_codegen_probe__f32_multiply' "$temporary/wide-probe.txt" "$temporary/wide_f32_multiply.txt"
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
        require_count '(^|[[:space:]])bl[[:space:]]' 2 "$temporary/wide_u8_add.txt" 'two inlined NEON byte-add leaves in wide caller'
        require_count '(^|[[:space:]])bl[[:space:]]' 2 "$temporary/wide_f32_multiply.txt" 'two NEON F32-multiply leaves in wide caller'
        require_count '(^|[[:space:]])bl[[:space:]]' 2 "$temporary/wide_f32_to_u32.txt" 'two NEON F32-to-U32 bit-cast leaves in wide caller'
        require_count '(^|[[:space:]])bl[[:space:]]' 2 "$temporary/wide_u8_widen.txt" 'two NEON byte-widen leaves in wide caller'
        require_count '(^|[[:space:]])bl[[:space:]]' 2 "$temporary/wide_u16_narrow.txt" 'two NEON U16-narrow leaves in wide caller'
        require_count '(^|[[:space:]])bl[[:space:]]' 2 "$temporary/wide_i32_to_f32.txt" 'two NEON I32-to-F32 conversion leaves in wide caller'
        require_count '(^|[[:space:]])bl[[:space:]]' 1 "$temporary/wide_u8_table_lookup.txt" 'one target-selected 32-lane table-lookup mechanism in wide caller'
        require_count '(^|[[:space:]])bl[[:space:]]' 2 "$temporary/wide_u8_horizontal_sum.txt" 'two exact byte-sum leaves in wide caller'
        for compact_probe in wide_u8_compress wide_u16_expand wide_f32_compress wide_f64_expand; do
            require_count 'tbl(\.16b)?[[:space:]]+v[0-9]+,.*\{[[:space:]]*v[0-9]+,[[:space:]]*v[0-9]+[[:space:]]*\},[[:space:]]*v[0-9]+' 2 \
              "$temporary/${compact_probe}.txt" \
              "two-register TBL operations in AArch64 ${compact_probe} caller"
            forbid_pattern 'flyology_simd__wide__(compact_mechanism|native)__(compress|expand)|flyology_simd__(__wide)?__(extract|from_lanes|test)' \
              "$temporary/${compact_probe}.txt" \
              "per-lane or dispatcher call in AArch64 ${compact_probe} caller"
        done
        require_count 'cmeq.*16b' 2 "$temporary/wide_u8_equal.txt" \
          'two NEON equality operations in the composed Wide U8 caller'
        forbid_pattern '(^|[[:space:]])bl[[:space:]]' "$temporary/wide_u8_equal.txt" \
          'out-of-line helper retained in the composed Wide U8 equality caller'
        for operation in less less_equal greater greater_equal; do
            require_count '(^|[[:space:]])bl[[:space:]]' 2 \
              "$temporary/wide_u8_${operation}.txt" \
              "two selected NEON operations in composed Wide U8 ${operation} caller"
            require_count '(^|[[:space:]])bl[[:space:]]' 2 \
              "$temporary/wide_i8_${operation}.txt" \
              "two selected NEON operations in composed Wide I8 ${operation} caller"
        done
        require_count '(^|[[:space:]])bl[[:space:]]' 2 "$temporary/wide_i8_equal.txt" \
          'two selected NEON operations in composed Wide I8 equality caller'
        require_count '(^|[[:space:]])bl[[:space:]]' 2 "$temporary/wide_u8_select.txt" \
          'two selected NEON operations in composed Wide U8 selection caller'
        require_count '(^|[[:space:]])bl[[:space:]]' 2 "$temporary/wide_i8_select.txt" \
          'two selected operations in composed Wide I8 selection caller'
        extract_symbol 'table_lookup_half' "$temporary/wide-lookup.txt" "$temporary/wide_lookup_leaf.txt"
        require_pattern 'tbl(\.16b)?[[:space:]]+v[0-9]+,.*\{[[:space:]]*v[0-9]+,[[:space:]]*v[0-9]+[[:space:]]*\},[[:space:]]*v[0-9]+' "$temporary/wide_lookup_leaf.txt" 'AArch64 32-entry byte-table lookup leaf'
        require_pattern 'flyology_simd__backends__native__(neon_)?add_wrap' "$temporary/wide-undefined.txt" 'wide U8 addition calls selected 128-bit native leaves after mechanism inlining'
        require_pattern 'flyology_simd__backends__native__multiply' "$temporary/wide-undefined.txt" 'wide F32 multiplication calls the selected 128-bit native leaf'
        require_pattern 'flyology_simd__backends__native__bit_cast' "$temporary/wide-undefined.txt" 'wide F32 bit cast calls the selected 128-bit native leaf'
        require_pattern 'flyology_simd__backends__native__widen_(low|high)' "$temporary/wide-undefined.txt" 'wide byte widening calls selected 128-bit native leaves'
        require_pattern 'flyology_simd__backends__native__narrow_saturate' "$temporary/wide-undefined.txt" 'wide U16 narrowing calls selected 128-bit native leaves'
        require_pattern 'flyology_simd__backends__native__convert_round' "$temporary/wide-undefined.txt" 'wide integer conversion calls selected 128-bit native leaves'
        require_pattern 'flyology_simd__wide__lookup_mechanism__table_lookup_32' "$temporary/wide-undefined.txt" 'wide lookup calls the target-selected lookup mechanism'
        require_pattern 'flyology_simd__backends__native__horizontal_sum' "$temporary/wide-undefined.txt" 'wide exact byte sum calls the selected 128-bit native leaf'
        require_pattern 'flyology_simd__backends__native__(greater|greater_equal|compare_|select_value)' "$temporary/wide-undefined.txt" 'wide byte predicates call selected 128-bit native operations'
        require_count 'flyology_simd__backends__native__((neon_)?add_wrap|multiply|bit_cast|widen_low|widen_high|narrow_saturate|convert_round|horizontal_sum|greater_bits|greater_equal_bits|compare_(greater(_equal)?_)?i8x16|select_value)|flyology_simd__select_value__2|flyology_simd__wide__lookup_mechanism__table_lookup_32' 16 "$temporary/wide-undefined.txt" 'only the intended native primitive classes remain unresolved from the wide probe'
        forbid_pattern 'flyology_simd__(wide__)?(add_wrap|multiply|bit_cast|widen_(low|high)|narrow_saturate|convert_round|table_lookup|horizontal_sum)' "$temporary/wide-undefined.txt" 'scalar or Wide primitive call from the native wide probe'
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
        require_pattern 'ldr[[:space:]]+q[0-9]+' "$temporary/native.txt" '128-bit unaligned load'
        require_pattern 'uaddlv' "$temporary/native.txt" 'vector mask/sum reduction'
        require_pattern 'sqadd.*(16b|8h|4s|2d)' "$temporary/native.txt" 'signed saturating arithmetic'
        require_pattern 'mul.*(16b|8h|4s)' "$temporary/native.txt" 'wrapping integer multiplication'
        require_pattern 'add.*8h' "$temporary/native.txt" '16-bit lane arithmetic'
        require_pattern 'add.*4s' "$temporary/native.txt" '32-bit lane arithmetic'
        require_pattern 'add.*2d' "$temporary/native.txt" '64-bit lane arithmetic'
        require_pattern 'cmgt.*(16b|8h|4s|2d)' "$temporary/native.txt" 'signed ordered comparison'
        require_pattern 'sshl.*(16b|8h|4s|2d)' "$temporary/native.txt" 'arithmetic right shift'
        require_pattern 'fadd.*(4s|2d)' "$temporary/native.txt" 'floating addition'
        require_pattern 'fmul.*(4s|2d)' "$temporary/native.txt" 'floating multiplication'
        require_pattern 'fdiv.*(4s|2d)' "$temporary/native.txt" 'floating division'
        require_pattern 'fminnm.*(4s|2d)' "$temporary/native.txt" 'IEEE minimum-number operation'
        require_pattern 'fmaxnm.*(4s|2d)' "$temporary/native.txt" 'IEEE maximum-number operation'
        require_pattern 'fminnm[[:space:]]+s0' "$temporary/native.txt" 'ordered F32 minimum-number reduction'
        require_pattern 'fmaxnm[[:space:]]+s0' "$temporary/native.txt" 'ordered F32 maximum-number reduction'
        require_pattern 'fminnm[[:space:]]+d0' "$temporary/native.txt" 'ordered F64 minimum-number reduction'
        require_pattern 'fmaxnm[[:space:]]+d0' "$temporary/native.txt" 'ordered F64 maximum-number reduction'
        require_pattern 'fcmeq.*(4s|2d)' "$temporary/native.txt" 'floating comparison'
        require_pattern '(uxtl|ushll)2?.*(8h|4s|2d)' "$temporary/native.txt" 'unsigned integer widening'
        require_pattern '(sxtl|sshll)2?.*(8h|4s|2d)' "$temporary/native.txt" 'signed integer widening'
        require_pattern 'fcvtl2?.*2d' "$temporary/native.txt" 'floating-point widening'
        require_pattern 'fcvtn2?.*(2s|4s)' "$temporary/native.txt" 'floating-point narrowing'
        require_pattern 'scvtf.*4s' "$temporary/native.txt" 'signed 32-bit integer-to-floating conversion'
        require_pattern 'scvtf.*2d' "$temporary/native.txt" 'signed 64-bit integer-to-floating conversion'
        require_pattern 'ucvtf.*4s' "$temporary/native.txt" 'unsigned 32-bit integer-to-floating conversion'
        require_pattern 'ucvtf.*2d' "$temporary/native.txt" 'unsigned 64-bit integer-to-floating conversion'
        require_pattern 'fcvtzs.*4s' "$temporary/native.txt" 'binary32-to-signed-32 truncating saturating conversion'
        require_pattern 'fcvtzs.*2d' "$temporary/native.txt" 'binary64-to-signed-64 truncating saturating conversion'
        require_pattern 'fcvtzu.*4s' "$temporary/native.txt" 'binary32-to-unsigned-32 truncating saturating conversion'
        require_pattern 'fcvtzu.*2d' "$temporary/native.txt" 'binary64-to-unsigned-64 truncating saturating conversion'
        extract_symbol 'native_convert_saturate_i8x16_to_u8x16' "$temporary/native.txt" "$temporary/i8_to_u8.txt"
        extract_symbol 'native_convert_saturate_u8x16_to_i8x16' "$temporary/native.txt" "$temporary/u8_to_i8.txt"
        extract_symbol 'native_convert_saturate_i16x8_to_u16x8' "$temporary/native.txt" "$temporary/i16_to_u16.txt"
        extract_symbol 'native_convert_saturate_u16x8_to_i16x8' "$temporary/native.txt" "$temporary/u16_to_i16.txt"
        extract_symbol 'native_convert_saturate_i32x4_to_u32x4' "$temporary/native.txt" "$temporary/i32_to_u32.txt"
        extract_symbol 'native_convert_saturate_u32x4_to_i32x4' "$temporary/native.txt" "$temporary/u32_to_i32.txt"
        extract_symbol 'native_convert_saturate_i64x2_to_u64x2' "$temporary/native.txt" "$temporary/i64_to_u64.txt"
        extract_symbol 'native_convert_saturate_u64x2_to_i64x2' "$temporary/native.txt" "$temporary/u64_to_i64.txt"
        require_pattern 'movi.*v1.*#(0x)?0+([,[:space:]]|$)' "$temporary/i8_to_u8.txt" 'signed-byte conversion zero construction'
        require_pattern 'smax.*16b' "$temporary/i8_to_u8.txt" 'signed-byte to unsigned-byte saturation'
        require_pattern 'movi.*v1.*#0xff([,[:space:]]|$)' "$temporary/u8_to_i8.txt" 'signed-byte maximum all-ones construction'
        require_pattern 'ushr.*16b.*#(0x)?1([,[:space:]]|$)' "$temporary/u8_to_i8.txt" 'signed-byte maximum construction'
        require_pattern 'umin.*16b' "$temporary/u8_to_i8.txt" 'unsigned-byte to signed-byte saturation'
        require_pattern 'movi.*v1.*#(0x)?0+([,[:space:]]|$)' "$temporary/i16_to_u16.txt" 'signed-16 conversion zero construction'
        require_pattern 'smax.*8h' "$temporary/i16_to_u16.txt" 'signed-16 to unsigned-16 saturation'
        require_pattern 'movi.*v1.*#0xff([,[:space:]]|$)' "$temporary/u16_to_i16.txt" 'signed-16 maximum all-ones construction'
        require_pattern 'ushr.*8h.*#(0x)?1([,[:space:]]|$)' "$temporary/u16_to_i16.txt" 'signed-16 maximum construction'
        require_pattern 'umin.*8h' "$temporary/u16_to_i16.txt" 'unsigned-16 to signed-16 saturation'
        require_pattern 'movi.*v1.*#(0x)?0+([,[:space:]]|$)' "$temporary/i32_to_u32.txt" 'signed-32 conversion zero construction'
        require_pattern 'smax.*4s' "$temporary/i32_to_u32.txt" 'signed-32 to unsigned-32 saturation'
        require_pattern 'movi.*v1.*#0xff([,[:space:]]|$)' "$temporary/u32_to_i32.txt" 'signed-32 maximum all-ones construction'
        require_pattern 'ushr.*4s.*#(0x)?1([,[:space:]]|$)' "$temporary/u32_to_i32.txt" 'signed-32 maximum construction'
        require_pattern 'umin.*4s' "$temporary/u32_to_i32.txt" 'unsigned-32 to signed-32 saturation'
        require_pattern 'cmge.*2d.*#(0x)?0+([,[:space:]]|$)' "$temporary/i64_to_u64.txt" 'signed-64 nonnegative mask'
        require_pattern 'and.*16b' "$temporary/i64_to_u64.txt" 'signed-64 to unsigned-64 saturation'
        require_pattern 'movi.*v1.*#0xff([,[:space:]]|$)' "$temporary/u64_to_i64.txt" 'signed-64 maximum all-ones construction'
        require_pattern 'ushr.*2d.*#(0x)?1([,[:space:]]|$)' "$temporary/u64_to_i64.txt" 'signed-64 maximum construction'
        require_pattern 'cmhi.*2d' "$temporary/u64_to_i64.txt" 'unsigned-64 clamp mask'
        require_pattern 'bsl.*16b' "$temporary/u64_to_i64.txt" 'unsigned-64 clamp selection'
        require_pattern 'mov.*v0.*v2' "$temporary/u64_to_i64.txt" 'unsigned-64 conversion result move'
        require_pattern '(^|[[:space:]])xtn2?\..*(16b|8h|4s)' "$temporary/native.txt" 'truncating integer narrowing'
        require_pattern '(^|[[:space:]])uqxtn2?\..*(16b|8h|4s)' "$temporary/native.txt" 'unsigned saturating narrowing'
        require_pattern '(^|[[:space:]])sqxtn2?\..*(16b|8h|4s)' "$temporary/native.txt" 'signed saturating narrowing'
        require_pattern '(^|[[:space:]])sqxtun2?\..*(16b|8h|4s)' "$temporary/native.txt" 'signed-to-unsigned saturating narrowing'
        require_pattern 'ldr[[:space:]]+q[0-9]+' "$temporary/algorithm.txt" \
          'inlined vector load in representative loop'
        require_pattern 'cmeq.*16b' "$temporary/algorithm.txt" \
          'inlined NEON comparison in representative loop'
        require_pattern 'uaddlv' "$temporary/algorithm.txt" \
          'inlined compact-mask extraction in representative loop'
        forbid_pattern 'bl.*equal_mask' "$temporary/native.txt" 'out-of-line mask helper call'
        ;;
    x86_64)
        require_pattern 'flyology_simd__wide__reduce_add' \
          "$temporary/wide-float-reduction-undefined.txt" \
          'portable ordered F32 addition reduction on x86-64'
        require_pattern 'flyology_simd__wide__reduce_min_number' \
          "$temporary/wide-float-reduction-undefined.txt" \
          'portable ordered F32 minimum-number reduction on x86-64'
        require_pattern 'flyology_simd__wide__reduce_max_number' \
          "$temporary/wide-float-reduction-undefined.txt" \
          'portable ordered F64 maximum-number reduction on x86-64'
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
                *flyology_simd-wide-permute_mechanism.o)
                    if [ "$wide_backend" = avx2 ]; then
                        continue
                    fi
                    ;;
            esac
            disassemble "$object" >>"$temporary/baseline.txt"
        done
        require_pattern 'pcmpeqb' "$temporary/native.txt" 'SSE2 byte comparison'
        require_pattern 'pcmpeqw' "$temporary/native.txt" 'SSE2 16-bit comparison'
        require_pattern 'pcmpeqd' "$temporary/native.txt" 'SSE2 32/64-bit comparison composition'
        require_pattern 'pmovmskb' "$temporary/native.txt" 'SSE2 compact mask extraction'
        require_pattern 'paddb' "$temporary/native.txt" 'SSE2 wrapping byte add'
        require_pattern 'paddw' "$temporary/native.txt" 'SSE2 wrapping 16-bit add'
        require_pattern 'paddd' "$temporary/native.txt" 'SSE2 wrapping 32-bit add'
        require_pattern 'paddq' "$temporary/native.txt" 'SSE2 wrapping 64-bit add'
        require_pattern 'psub(b|w|d|q)' "$temporary/native.txt" 'SSE2 wrapping subtraction family'
        require_pattern 'paddusb' "$temporary/native.txt" 'SSE2 saturating byte add'
        require_pattern 'paddusw' "$temporary/native.txt" 'SSE2 unsigned saturating 16-bit add'
        require_pattern 'paddsw' "$temporary/native.txt" 'SSE2 signed saturating 16-bit add'
        require_pattern 'psubusb' "$temporary/native.txt" 'SSE2 saturating byte subtract'
        require_pattern 'pmullw' "$temporary/native.txt" 'SSE2 8/16-bit multiplication composition'
        require_pattern 'pmuludq' "$temporary/native.txt" 'SSE2 32/64-bit multiplication composition'
        require_pattern 'pcmpgt(b|w|d)' "$temporary/native.txt" 'SSE2 ordered integer comparisons'
        require_pattern 'psll(w|d|q)' "$temporary/native.txt" 'SSE2 logical left shifts'
        require_pattern 'psrl(w|d|q)' "$temporary/native.txt" 'SSE2 logical right shifts'
        require_pattern 'psra(w|d)' "$temporary/native.txt" 'SSE2 arithmetic right shifts'
        require_pattern 'pandn' "$temporary/native.txt" 'SSE2 mask selection'
        require_pattern 'punpckl(bw|wd|dq|qdq)' "$temporary/native.txt" 'SSE2 interleave family'
        require_pattern 'pshuf(d|lw|hw)' "$temporary/native.txt" 'SSE2 reverse/shuffle family'
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
        require_pattern 'addps' "$temporary/native.txt" 'SSE floating32 addition'
        require_pattern 'addpd' "$temporary/native.txt" 'SSE2 floating64 addition'
        require_pattern 'mul(ps|pd)' "$temporary/native.txt" 'SSE/SSE2 floating multiplication'
        require_pattern 'div(ps|pd)' "$temporary/native.txt" 'SSE/SSE2 floating division'
        require_pattern 'cmp(unord|eq|lt|le)(ps|pd)' "$temporary/native.txt" 'SSE/SSE2 floating comparisons'
        require_pattern 'movdqu' "$temporary/native.txt" 'unaligned SSE2 load/store'
        require_pattern 'movdqa' "$temporary/native.txt" 'aligned SSE2 load/store'
        extract_symbol 'wide_codegen_probe__u8_add' "$temporary/wide-probe.txt" "$temporary/wide_u8_add.txt"
        extract_symbol 'wide_codegen_probe__f32_multiply' "$temporary/wide-probe.txt" "$temporary/wide_f32_multiply.txt"
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
        if [ "$wide_backend" = avx2 ]; then
            require_count '(^|[[:space:]])call' 1 "$temporary/wide_u8_add.txt" 'one isolated AVX2 byte-operation mechanism in wide caller'
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
            require_count '(^|[[:space:]])call' 2 "$temporary/wide_u8_add.txt" 'two inlined SSE2 byte-add leaves in wide caller'
        fi
        require_count '(^|[[:space:]])call' 2 "$temporary/wide_f32_multiply.txt" 'two SSE F32-multiply leaves in wide caller'
        require_count '(^|[[:space:]])call' 2 "$temporary/wide_f32_to_u32.txt" 'two SSE F32-to-U32 bit-cast leaves in wide caller'
        require_count '(^|[[:space:]])call' 2 "$temporary/wide_u8_widen.txt" 'two selected byte-widen operations in wide caller'
        require_count '(^|[[:space:]])call' 2 "$temporary/wide_u16_narrow.txt" 'two selected U16-narrow operations in wide caller'
        require_count '(^|[[:space:]])call' 2 "$temporary/wide_i32_to_f32.txt" 'two selected I32-to-F32 conversion operations in wide caller'
        require_count '(^|[[:space:]])call' 1 "$temporary/wide_u8_table_lookup.txt" 'one target-selected 32-lane table-lookup mechanism in wide caller'
        require_count '(^|[[:space:]])call' 2 "$temporary/wide_u8_horizontal_sum.txt" 'two exact byte-sum operations in wide caller'
        if [ "$wide_backend" = avx2 ]; then
            for lane_kind in u8 i8; do
                for operation in equal less less_equal greater greater_equal select; do
                    require_count '(^|[[:space:]])(call|jmp)[[:space:]]' 1 \
                      "$temporary/wide_${lane_kind}_${operation}.txt" \
                      "one isolated AVX2 ${lane_kind} ${operation} mechanism in wide caller"
                    forbid_pattern '(^|[[:space:]])(call|jmp).*backends__native|(^|[[:space:]])(call|jmp).*flyology_simd__(wide__)?(equal|less|greater|select_value)' \
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
                require_count '(^|[[:space:]])call' 2 \
                  "$temporary/wide_u8_${operation}.txt" \
                  "two selected SSE2 U8 ${operation} operations in composed Wide caller"
            done
            for operation in less_equal greater_equal; do
                require_count '(^|[[:space:]])call' 2 \
                  "$temporary/wide_u8_${operation}.txt" \
                  "two selected SSE2 U8 ordered operations in composed Wide ${operation} caller"
                require_count 'pcmpeqb' 2 "$temporary/wide_u8_${operation}.txt" \
                  "two inlined SSE2 U8 equality operations in composed Wide ${operation} caller"
            done
            for operation in equal less greater select; do
                require_count '(^|[[:space:]])call' 2 \
                  "$temporary/wide_i8_${operation}.txt" \
                  "two selected SSE2 I8 ${operation} operations in composed Wide caller"
            done
            for operation in less_equal greater_equal; do
                require_count '(^|[[:space:]])call' 4 \
                  "$temporary/wide_i8_${operation}.txt" \
                  "four selected SSE2 I8 compare operations in composed Wide ${operation} caller"
            done
        fi
        if [ "$wide_backend" = avx2 ]; then
            require_pattern 'flyology_simd__wide__byte_avx2_leaf__add_wrap' "$temporary/wide-undefined.txt" 'wide U8 addition calls the isolated AVX2 byte implementation'
            require_pattern 'flyology_simd__wide__byte_avx2_leaf__(equal|greater_than|select_value)' "$temporary/wide-undefined.txt" 'wide byte predicates call isolated AVX2 implementations'
            forbid_pattern 'flyology_simd__wide__byte_mechanism__' "$temporary/wide-undefined.txt" 'non-AVX2 byte mechanism call retained in the public Wide caller'
        else
            require_pattern 'flyology_simd__backends__native__(u8_)?add_wrap' "$temporary/wide-undefined.txt" 'wide U8 addition calls selected 128-bit native leaves after mechanism inlining'
        fi
        require_pattern 'flyology_simd__backends__native__multiply' "$temporary/wide-undefined.txt" 'wide F32 multiplication calls the selected 128-bit native leaf'
        require_pattern 'flyology_simd__backends__native__bit_cast' "$temporary/wide-undefined.txt" 'wide F32 bit cast calls the selected 128-bit native leaf'
        require_pattern 'flyology_simd__backends__native__widen_(low|high)' "$temporary/wide-undefined.txt" 'wide byte widening calls selected 128-bit native leaves'
        require_pattern 'flyology_simd__backends__native__narrow_saturate' "$temporary/wide-undefined.txt" 'wide U16 narrowing calls selected 128-bit native leaves'
        require_pattern 'flyology_simd__backends__native__convert_round' "$temporary/wide-undefined.txt" 'wide integer conversion calls selected 128-bit native leaves'
        require_pattern 'flyology_simd__wide__lookup_mechanism__table_lookup_32' "$temporary/wide-undefined.txt" 'wide lookup calls the target-selected lookup mechanism'
        require_pattern 'flyology_simd__backends__native__horizontal_sum' "$temporary/wide-undefined.txt" 'wide exact byte sum calls the selected 128-bit native leaf'
        if [ "$wide_backend" = avx2 ]; then
            require_count 'flyology_simd__backends__native__(multiply|bit_cast|widen_low|widen_high|narrow_saturate|convert_round|horizontal_sum)|flyology_simd__wide__(byte_avx2_leaf__(add_wrap|equal|equal__2|greater_than|greater_than__2|select_value|select_value__2)|lookup_mechanism__table_lookup_32)' 15 "$temporary/wide-undefined.txt" 'only the intended native primitive classes remain unresolved from the AVX2 wide probe'
        else
            require_count 'flyology_simd__backends__native__((u8_)?add_wrap|multiply|bit_cast|widen_low|widen_high|narrow_saturate|convert_round|horizontal_sum|compare_(equal|greater)(_i8x16)?|native_select_(u8|i8)x16)|flyology_simd__wide__lookup_mechanism__table_lookup_32' 12 "$temporary/wide-undefined.txt" 'only the intended native primitive classes remain unresolved from the composed wide probe'
        fi
        forbid_pattern 'flyology_simd__(wide__)?(add_wrap|multiply|bit_cast|widen_(low|high)|narrow_saturate|convert_round|table_lookup|horizontal_sum)' "$temporary/wide-undefined.txt" 'scalar or Wide primitive call from the native wide probe'
        forbid_pattern 'flyology_simd__wide__native__(add_wrap|multiply|bit_cast|widen_(low|high)|narrow_saturate|convert_round|table_lookup|horizontal_sum)' "$temporary/wide-probe.txt" 'wide native dispatcher call in caller probe'
        require_pattern 'pcmpeqb' "$temporary/algorithm.txt" 'inlined SSE2 comparison in representative loop'
        require_pattern 'pmovmskb' "$temporary/algorithm.txt" 'inlined mask extraction in representative loop'
        require_pattern 'movdqu' "$temporary/algorithm.txt" 'inlined vector load in representative loop'
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
            require_pattern 'ymm[0-9]+|vp[a-z]+' "$temporary/avx2.txt" \
              'AVX2 vectorization in the AVX2-only algorithm object'
            require_pattern 'bsf' "$temporary/avx2.txt" \
              'constant-time first-set-bit extraction in the AVX2 algorithm'
        fi
        if [ "$wide_backend" = avx2 ]; then
            forbid_pattern 'flyology_simd__(__wide)?__(extract|from_lanes|permute_lanes)' "$temporary/wide-permute.txt" 'scalar or per-lane helper in AVX2 permutation object'
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
            extract_symbol 'byte_avx2_leaf__select_value' "$temporary/wide-byte.txt" "$temporary/wide_byte_u8_select.txt"
            extract_symbol 'byte_avx2_leaf__select_value__2' "$temporary/wide-byte.txt" "$temporary/wide_byte_i8_select.txt"
            require_pattern 'vpaddb' "$temporary/wide_byte_u8_add.txt" 'AVX2 unsigned wrapping byte addition'
            require_pattern 'vpaddb' "$temporary/wide_byte_i8_add.txt" 'AVX2 signed wrapping byte addition'
            require_pattern 'vpsubb' "$temporary/wide_byte_u8_subtract.txt" 'AVX2 unsigned wrapping byte subtraction'
            require_pattern 'vpsubb' "$temporary/wide_byte_i8_subtract.txt" 'AVX2 signed wrapping byte subtraction'
            require_pattern 'vpmullw' "$temporary/wide_byte_u8_multiply.txt" 'AVX2 unsigned wrapping byte multiplication composition'
            require_pattern 'vpmullw' "$temporary/wide_byte_i8_multiply.txt" 'AVX2 signed wrapping byte multiplication composition'
            require_pattern 'vpand' "$temporary/wide_byte_u8_multiply.txt" 'AVX2 unsigned wrapping byte product truncation'
            require_pattern 'vpand' "$temporary/wide_byte_i8_multiply.txt" 'AVX2 signed wrapping byte product truncation'
            require_pattern 'vpsrlw' "$temporary/wide_byte_u8_multiply.txt" 'AVX2 unsigned odd-byte extraction'
            require_pattern 'vpsrlw' "$temporary/wide_byte_i8_multiply.txt" 'AVX2 signed odd-byte extraction'
            require_pattern 'vpsllw' "$temporary/wide_byte_u8_multiply.txt" 'AVX2 unsigned odd-byte placement'
            require_pattern 'vpsllw' "$temporary/wide_byte_i8_multiply.txt" 'AVX2 signed odd-byte placement'
            require_pattern 'vpaddusb' "$temporary/wide_byte_u8_add_sat.txt" 'AVX2 unsigned saturating byte addition'
            require_pattern 'vpaddsb' "$temporary/wide_byte_i8_add_sat.txt" 'AVX2 signed saturating byte addition'
            require_pattern 'vpsubusb' "$temporary/wide_byte_u8_sub_sat.txt" 'AVX2 unsigned saturating byte subtraction'
            require_pattern 'vpsubsb' "$temporary/wide_byte_i8_sub_sat.txt" 'AVX2 signed saturating byte subtraction'
            require_pattern 'vpand' "$temporary/wide_byte_u8_and.txt" 'AVX2 unsigned byte bitwise conjunction'
            require_pattern 'vpand' "$temporary/wide_byte_i8_and.txt" 'AVX2 signed byte bitwise conjunction'
            require_pattern 'vpor' "$temporary/wide_byte_u8_or.txt" 'AVX2 unsigned byte bitwise disjunction'
            require_pattern 'vpor' "$temporary/wide_byte_i8_or.txt" 'AVX2 signed byte bitwise disjunction'
            require_pattern 'vpxor' "$temporary/wide_byte_u8_xor.txt" 'AVX2 unsigned byte bitwise exclusive disjunction'
            require_pattern 'vpxor' "$temporary/wide_byte_i8_xor.txt" 'AVX2 signed byte bitwise exclusive disjunction'
            require_pattern 'vpcmpeqd' "$temporary/wide_byte_u8_not.txt" 'AVX2 unsigned byte complement mask'
            require_pattern 'vpxor' "$temporary/wide_byte_u8_not.txt" 'AVX2 unsigned byte complement'
            require_pattern 'vpcmpeqd' "$temporary/wide_byte_i8_not.txt" 'AVX2 signed byte complement mask'
            require_pattern 'vpxor' "$temporary/wide_byte_i8_not.txt" 'AVX2 signed byte complement'
            require_pattern 'vpminub' "$temporary/wide_byte_u8_min.txt" 'AVX2 unsigned byte minimum'
            require_pattern 'vpminsb' "$temporary/wide_byte_i8_min.txt" 'AVX2 signed byte minimum'
            require_pattern 'vpmaxub' "$temporary/wide_byte_u8_max.txt" 'AVX2 unsigned byte maximum'
            require_pattern 'vpmaxsb' "$temporary/wide_byte_i8_max.txt" 'AVX2 signed byte maximum'
            require_pattern 'vpcmpeqb' "$temporary/wide_byte_u8_equal.txt" 'AVX2 unsigned byte equality'
            require_pattern 'vpcmpeqb' "$temporary/wide_byte_i8_equal.txt" 'AVX2 signed byte equality'
            require_pattern 'vpmovmskb' "$temporary/wide_byte_u8_equal.txt" 'AVX2 unsigned compact equality mask'
            require_pattern 'vpmovmskb' "$temporary/wide_byte_i8_equal.txt" 'AVX2 signed compact equality mask'
            require_pattern 'vpcmpgtb' "$temporary/wide_byte_u8_greater.txt" 'AVX2 unsigned byte ordering compare'
            require_pattern 'vpcmpgtb' "$temporary/wide_byte_i8_greater.txt" 'AVX2 signed byte ordering compare'
            require_count 'vpxor' 2 "$temporary/wide_byte_u8_greater.txt" 'two AVX2 unsigned sign-bit bias transforms'
            require_pattern 'vpmovmskb' "$temporary/wide_byte_u8_greater.txt" 'AVX2 unsigned compact ordered mask'
            require_pattern 'vpmovmskb' "$temporary/wide_byte_i8_greater.txt" 'AVX2 signed compact ordered mask'
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
  'flyology_simd__backends__native__(splat|load_unaligned|equal|bitwise_and|to_bit_mask|equal_bits|neon_bitwise_and|u8_and)$'; then
    echo "representative native algorithm retains an out-of-line backend primitive" >&2
    exit 1
fi

echo "code-generation checks passed: architecture=$architecture avx2=$avx2 wide_backend=$wide_backend"
