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
        forbid_pattern 'bl.*equal_mask' "$temporary/native.txt" 'out-of-line mask helper call'
        ;;
    x86_64)
        require_pattern 'pcmpeqb' "$temporary/native.txt" 'SSE2 byte comparison'
        require_pattern 'pmovmskb' "$temporary/native.txt" 'SSE2 compact mask extraction'
        require_pattern 'paddb' "$temporary/native.txt" 'SSE2 wrapping byte add'
        require_pattern 'paddusb' "$temporary/native.txt" 'SSE2 saturating byte add'
        require_pattern 'movdqu' "$temporary/native.txt" 'unaligned SSE2 load/store'
        forbid_pattern '(^|[^a-z])(ymm[0-9]+|v(p|mov|add|sub|and|or|xor))' \
          "$temporary/native.txt" 'AVX instructions in the SSE2 baseline object'
        forbid_pattern '(^|[^a-z])(ymm[0-9]+|v(p|mov|add|sub|and|or|xor))' \
          "$temporary/features.txt" 'AVX instructions in feature detection'
        if [ "$avx2" = enabled ]; then
            avx_object="obj/x86_64/enabled/flyology_simd-algorithms-avx2.o"
            disassemble "$avx_object" >"$temporary/avx2.txt"
            require_pattern 'ymm[0-9]+|vp[a-z]+' "$temporary/avx2.txt" \
              'AVX2 vectorization in the AVX2-only algorithm object'
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

echo "code-generation checks passed: architecture=$architecture avx2=$avx2"
