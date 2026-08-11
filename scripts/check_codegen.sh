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

native_object="obj/$architecture/$avx2/flyology_simd-backends-native.o"
algorithm_object="obj/$architecture/$avx2/flyology_simd-algorithms-native.o"
feature_object="obj/$architecture/$avx2/flyology_simd-features.o"

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
        require_pattern 'fcmeq.*(4s|2d)' "$temporary/native.txt" 'floating comparison'
        require_pattern '(uxtl|ushll)2?.*(8h|4s|2d)' "$temporary/native.txt" 'unsigned integer widening'
        require_pattern '(sxtl|sshll)2?.*(8h|4s|2d)' "$temporary/native.txt" 'signed integer widening'
        require_pattern 'fcvtl2?.*2d' "$temporary/native.txt" 'floating-point widening'
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
