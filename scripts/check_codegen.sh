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
        require_pattern 'uqadd' "$temporary/native.txt" 'NEON saturating byte add'
        require_pattern 'ldr[[:space:]]+q[0-9]+' "$temporary/native.txt" '128-bit unaligned load'
        require_pattern 'uaddlv' "$temporary/native.txt" 'vector comparison-mask reduction'
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
