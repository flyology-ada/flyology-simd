#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
architecture=${1:-aarch64}
avx2=${2:-disabled}
temporary=$(mktemp -d "${TMPDIR:-/tmp}/flyology-simd-codegen.XXXXXX")
trap 'rm -rf "$temporary"' EXIT HUP INT TERM

cd "$project_root"
alr build -- "-XFLYOLOGY_SIMD_ARCH=$architecture" \
  "-XFLYOLOGY_SIMD_AVX2=$avx2"
alr exec -- gprbuild -f -p -P scripts/codegen_probes.gpr \
  "-XFLYOLOGY_SIMD_ARCH=$architecture" \
  "-XFLYOLOGY_SIMD_AVX2=$avx2"

native_object="obj/$architecture/$avx2/flyology_simd-backends-native.o"
algorithm_object="obj/$architecture/$avx2/flyology_simd-algorithms-native.o"
feature_object="obj/$architecture/$avx2/flyology_simd-features.o"
slide_probe_object="obj/codegen-probes/$architecture/$avx2/slide_codegen_probe.o"
permute_probe_object="obj/codegen-probes/$architecture/$avx2/permute_codegen_probe.o"

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

case "$architecture" in
    aarch64)
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
        : >"$temporary/baseline.txt"
        for object in "obj/x86_64/$avx2"/*.o; do
            case "$object" in
                *flyology_simd-algorithms-avx2_implementation.o) continue ;;
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
        require_pattern 'pcmpeqb' "$temporary/algorithm.txt" 'inlined SSE2 comparison in representative loop'
        require_pattern 'pmovmskb' "$temporary/algorithm.txt" 'inlined mask extraction in representative loop'
        require_pattern 'movdqu' "$temporary/algorithm.txt" 'inlined vector load in representative loop'
        forbid_pattern '(^|[^a-z])(ymm[0-9]+|v(p|mov|add|sub|and|or|xor))' \
          "$temporary/native.txt" 'AVX instructions in the SSE2 baseline object'
        forbid_pattern '(^|[^a-z])(ymm[0-9]+|v(p|mov|add|sub|and|or|xor))' \
          "$temporary/features.txt" 'AVX instructions in feature detection'
        forbid_pattern '(^|[^a-z])(ymm[0-9]+|v(p|mov|add|sub|and|or|xor))' \
          "$temporary/baseline.txt" 'AVX instructions outside the AVX2-only object'
        if [ "$avx2" = enabled ]; then
            avx_object="obj/x86_64/enabled/flyology_simd-algorithms-avx2_implementation.o"
            disassemble "$avx_object" >"$temporary/avx2.txt"
            require_pattern 'ymm[0-9]+|vp[a-z]+' "$temporary/avx2.txt" \
              'AVX2 vectorization in the AVX2-only algorithm object'
            require_pattern 'bsf' "$temporary/avx2.txt" \
              'constant-time first-set-bit extraction in the AVX2 algorithm'
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

echo "code-generation checks passed: architecture=$architecture avx2=$avx2"
