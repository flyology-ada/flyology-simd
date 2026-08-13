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
wide_compact_probe_object="$probe_root/wide_compact_codegen_probe.o"
wide_movement_probe_object="$probe_root/wide_movement_codegen_probe.o"
wide_numeric_conversion_probe_object="$probe_root/wide_numeric_conversion_codegen_probe.o"
wide_memory_probe_object="$probe_root/wide_memory_codegen_probe.o"
float_reduction_probe_object="$probe_root/float_reduction_codegen_probe.o"
conversion64_probe_object="$probe_root/conversion64_codegen_probe.o"
integer_shift_probe_object="$probe_root/integer_shift_codegen_probe.o"
unordered_probe_object="$probe_root/unordered_codegen_probe.o"
mask_position_probe_object="$probe_root/mask_position_codegen_probe.o"
construction_probe_object="$probe_root/construction_codegen_probe.o"
partial_memory_probe_object="$probe_root/partial_memory_codegen_probe.o"
bit_cast_probe_object="$probe_root/bit_cast_codegen_probe.o"
alignment_probe_object="$probe_root/alignment_codegen_probe.o"
table_lookup_probe_object="$probe_root/table_lookup_codegen_probe.o"
u8_value_probe_object="$probe_root/u8_value_codegen_probe.o"
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
disassemble "$algorithm_object" >"$temporary/algorithm.txt"
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
nm -u "$construction_probe_object" >"$temporary/construction-undefined.txt"
nm -u "$partial_memory_probe_object" >"$temporary/partial-memory-undefined.txt"
nm -u "$bit_cast_probe_object" >"$temporary/bit-cast-undefined.txt"
nm -u "$alignment_probe_object" >"$temporary/alignment-undefined.txt"
nm -u "$table_lookup_probe_object" >"$temporary/table-lookup-undefined.txt"
nm -u "$u8_value_probe_object" >"$temporary/u8-value-undefined.txt"
nm -u "$permute_probe_object" >"$temporary/permute-undefined.txt"
nm "$alignment_probe_object" >"$temporary/alignment-symbols.txt"
nm -u "$native_object" >"$temporary/native-undefined.txt"

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
    ' "$file" >"$output"
}

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

require_count 'flyology_simd__backends__native__reduce_add' 2 \
  "$temporary/float-reduction-undefined.txt" \
  'two Native floating Reduce_Add calls in the public caller probe'
forbid_pattern 'flyology_simd__reduce_add' \
  "$temporary/float-reduction-undefined.txt" \
  'portable Reduce_Add call in the Native caller probe'
require_count 'flyology_simd__backends__native__min_number' 2 \
  "$temporary/float-reduction-undefined.txt" \
  'two Native floating Min_Number calls in the public caller probe'
require_count 'flyology_simd__backends__native__max_number' 2 \
  "$temporary/float-reduction-undefined.txt" \
  'two Native floating Max_Number calls in the public caller probe'
require_count 'flyology_simd__backends__native__reduce_min_number' 2 \
  "$temporary/float-reduction-undefined.txt" \
  'two Native floating Reduce_Min_Number calls in the public caller probe'
require_count 'flyology_simd__backends__native__reduce_max_number' 2 \
  "$temporary/float-reduction-undefined.txt" \
  'two Native floating Reduce_Max_Number calls in the public caller probe'
forbid_pattern 'flyology_simd__(min_number|max_number|reduce_min_number|reduce_max_number)' \
  "$temporary/float-reduction-undefined.txt" \
  'portable floating min/max call in the Native caller probe'
require_count 'flyology_simd__backends__native__convert_round' 2 \
  "$temporary/conversion64-undefined.txt" \
  'I64x2-to-F64x2 and U64x2-to-F64x2 Native calls in the public caller probe'
require_count 'flyology_simd__backends__native__convert_truncate_saturate' 2 \
  "$temporary/conversion64-undefined.txt" \
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
    require_count "flyology_simd__backends__native__${selected}" 2 \
      "$temporary/wide_numeric_${conversion}.txt" \
      "two matching selected 128-bit calls in Wide ${conversion} conversion"
    require_count 'flyology_simd__backends__native__convert_(round|truncate_saturate)' 2 \
      "$temporary/wide_numeric_${conversion}.txt" \
      "no mismatched selected call in Wide ${conversion} conversion"
    forbid_pattern 'flyology_simd__(wide__)?(convert_round|convert_truncate_saturate)|flyology_simd__wide__native__' \
      "$temporary/wide_numeric_${conversion}.txt" \
      "portable or public dispatcher call in Wide ${conversion} conversion"
done
require_count 'flyology_simd__backends__native__convert_(round|truncate_saturate)' 8 \
  "$temporary/wide-numeric-conversion-undefined.txt" \
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
        require_count "flyology_simd__backends__native__widen_low${suffix}" 1 \
          "$temporary/wide_non_numeric_${caller}.txt" \
          "one matching selected low-half widening call in Wide ${caller} conversion"
        require_count "flyology_simd__backends__native__widen_high${suffix}" 1 \
          "$temporary/wide_non_numeric_${caller}.txt" \
          "one matching selected high-half widening call in Wide ${caller} conversion"
        require_count 'flyology_simd__backends__native__widen_(low|high)' 2 \
          "$temporary/wide_non_numeric_${caller}.txt" \
          "no extra or mismatched selected call in Wide ${caller} conversion"
    else
        require_count "flyology_simd__backends__native__${operation}${suffix}" 2 \
          "$temporary/wide_non_numeric_${caller}.txt" \
          "two matching selected 128-bit calls in Wide ${caller} conversion"
        require_count "flyology_simd__backends__native__${operation}" 2 \
          "$temporary/wide_non_numeric_${caller}.txt" \
          "no extra or mismatched selected call in Wide ${caller} conversion"
    fi
    portable_operation=$operation
    if [ "$operation" = widen ]; then portable_operation='widen_(low|high)'; fi
    forbid_pattern "flyology_simd__(wide__)?${portable_operation}|flyology_simd__wide__native__" \
      "$temporary/wide_non_numeric_${caller}.txt" \
      "portable or public dispatcher call in Wide ${caller} conversion"
done <"$non_numeric_conversion_cases"
require_count 'flyology_simd__backends__native__(widen_(low|high)|narrow_(truncate|saturate|round)|convert_saturate)' 38 \
  "$temporary/wide-numeric-conversion-undefined.txt" \
  'all 38 selected non-numeric conversion symbols in the Wide conversion probe'
require_count 'flyology_simd__' 46 \
  "$temporary/wide-numeric-conversion-undefined.txt" \
  'only the 38 non-numeric and eight numeric conversion symbols remain unresolved'
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
            require_count "flyology_simd__backends__native__${operation}${suffix}" 2 \
              "$temporary/wide_memory_${caller}.txt" \
              "two matching selected 128-bit ${operation} calls in Wide ${caller}"
            require_count "flyology_simd__backends__native__${operation}" 2 \
              "$temporary/wide_memory_${caller}.txt" \
              "no extra or mismatched selected ${operation} call in Wide ${caller}"
            ;;
        load_unaligned|store_unaligned|load_aligned|store_aligned)
            if [ "$caller" != u8_load_unaligned ]; then
                require_count "flyology_simd__backends__native__${operation}${suffix}" 2 \
                  "$temporary/wide_memory_${caller}.txt" \
                  "two matching selected 128-bit ${operation} calls in Wide ${caller}"
                require_count "flyology_simd__backends__native__${operation}" 2 \
                  "$temporary/wide_memory_${caller}.txt" \
                  "no extra or mismatched selected ${operation} call in Wide ${caller}"
            elif [ "$architecture" = scalar ]; then
                require_count "flyology_simd__load_unaligned${symbol_end}" 2 \
                  "$temporary/wide_memory_${caller}.txt" \
                  "two portable 128-bit unaligned loads in scalar Wide ${caller}"
                require_count 'flyology_simd__backends__native__load_unaligned' 0 \
                  "$temporary/wide_memory_${caller}.txt" \
                  "scalar Wide ${caller} resolves the selected rename directly"
            elif [ "$architecture" = aarch64 ]; then
                require_count 'flyology_simd__backends__native__load_unaligned' 0 \
                  "$temporary/wide_memory_${caller}.txt" \
                  "selected unaligned load is fully inlined in Wide ${caller}"
                require_count '(^|[[:space:]])ldr[[:space:]]+q[0-9]+' 2 \
                  "$temporary/wide_memory_${caller}.txt" \
                  "two inlined 128-bit loads in Wide ${caller}"
                require_count '(^|[[:space:]])str[[:space:]]+q[0-9]+' 2 \
                  "$temporary/wide_memory_${caller}.txt" \
                  "two inlined 128-bit result stores in Wide ${caller}"
            else
                require_count "flyology_simd__backends__native__${operation}" 0 \
                  "$temporary/wide_memory_${caller}.txt" \
                  "selected ${operation} is fully inlined in Wide ${caller}"
                require_count '(^|[[:space:]])movdqu[[:space:]]' 4 \
                  "$temporary/wide_memory_${caller}.txt" \
                  "two inlined SSE2 unaligned transfers in Wide ${caller}"
            fi
            ;;
        load_partial)
            require_count "flyology_simd__backends__native__load_partial${suffix}" 2 \
              "$temporary/wide_memory_${caller}.txt" \
              "both branches use the matching selected partial load in Wide ${caller}"
            require_count "flyology_simd__backends__native__load${suffix}" 1 \
              "$temporary/wide_memory_${caller}.txt" \
              "one matching selected full load in Wide ${caller}"
            require_count "flyology_simd__backends__native__zero${suffix}" 1 \
              "$temporary/wide_memory_${caller}.txt" \
              "one matching selected zero in Wide ${caller}"
            require_count 'flyology_simd__backends__native__load_partial' 2 \
              "$temporary/wide_memory_${caller}.txt" \
              "no mismatched partial load in Wide ${caller}"
            require_count "flyology_simd__backends__native__load(__[0-9]+)?${symbol_end}" 1 \
              "$temporary/wide_memory_${caller}.txt" \
              "no mismatched full load in Wide ${caller}"
            require_count "flyology_simd__backends__native__zero(__[0-9]+)?${symbol_end}" 1 \
              "$temporary/wide_memory_${caller}.txt" \
              "no mismatched zero in Wide ${caller}"
            ;;
        store_partial)
            require_count "flyology_simd__backends__native__store_partial${suffix}" 2 \
              "$temporary/wide_memory_${caller}.txt" \
              "both branches use the matching selected partial store in Wide ${caller}"
            require_count "flyology_simd__backends__native__store${suffix}" 1 \
              "$temporary/wide_memory_${caller}.txt" \
              "one matching selected full store in Wide ${caller}"
            require_count 'flyology_simd__backends__native__store_partial' 2 \
              "$temporary/wide_memory_${caller}.txt" \
              "no mismatched partial store in Wide ${caller}"
            require_count "flyology_simd__backends__native__store(__[0-9]+)?${symbol_end}" 1 \
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
    require_count "flyology_simd__backends__native__${operation}($|__)" 10 \
      "$temporary/wide-memory-undefined.txt" \
      "all ten selected ${operation} symbols in the Wide memory probe"
done
require_count 'flyology_simd__backends__native__load_unaligned($|__)' 9 \
  "$temporary/wide-memory-undefined.txt" \
  'nine out-of-line selected unaligned loads plus the inlined U8 load path'
for operation in store_unaligned load_aligned store_aligned; do
    require_count "flyology_simd__backends__native__${operation}($|__)" 10 \
      "$temporary/wide-memory-undefined.txt" \
      "all ten selected ${operation} symbols in the Wide memory probe"
done
require_count 'flyology_simd__backends__native__zero($|__)' 10 \
  "$temporary/wide-memory-undefined.txt" \
  'all ten selected zero symbols for Wide partial loads'
if [ "$architecture" = scalar ]; then
    require_count "flyology_simd__load_unaligned${symbol_end}" 1 \
      "$temporary/wide-memory-undefined.txt" \
      'one portable U8 unaligned-load rename in the scalar Wide probe'
    require_count 'flyology_simd__' 90 \
      "$temporary/wide-memory-undefined.txt" \
      'only the selected memory and zero symbols remain unresolved in the scalar probe'
    forbid_pattern 'flyology_simd__wide__(load|store)|flyology_simd__wide__native__' \
      "$temporary/wide-memory-undefined.txt" \
      'Wide or public memory symbols in the all-family scalar probe'
else
    require_count 'flyology_simd__' 89 \
      "$temporary/wide-memory-undefined.txt" \
      'only the selected memory and zero symbols remain unresolved'
    forbid_pattern 'flyology_simd__(wide__)?(load|store)|flyology_simd__wide__native__' \
      "$temporary/wide-memory-undefined.txt" \
      'portable or public memory symbols in the all-family Wide probe'
fi
require_count 'flyology_simd__backends__native__shift_right_arithmetic' 4 \
  "$temporary/integer-shift-undefined.txt" \
  'all four Native arithmetic-right-shift calls in the public caller probe'
forbid_pattern 'flyology_simd__shift_right_arithmetic' \
  "$temporary/integer-shift-undefined.txt" \
  'portable arithmetic-right-shift call in the Native caller probe'
require_count 'flyology_simd__backends__native__shift_left_logical' 8 \
  "$temporary/integer-shift-undefined.txt" \
  'all eight Native logical-left-shift calls in the public caller probe'
require_count 'flyology_simd__backends__native__shift_right_logical' 8 \
  "$temporary/integer-shift-undefined.txt" \
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
require_count 'flyology_simd__backends__native__table_lookup' 1 \
  "$temporary/table-lookup-undefined.txt" \
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
require_count 'flyology_simd__backends__native__unordered' 2 \
  "$temporary/unordered-undefined.txt" \
  'F32x4 and F64x2 Native Unordered calls in the public caller probe'
forbid_pattern 'flyology_simd__unordered' \
  "$temporary/unordered-undefined.txt" \
  'portable Unordered call in the Native caller probe'
require_count 'flyology_simd__backends__native__first_true' 4 \
  "$temporary/mask-position-undefined.txt" \
  'four Native First_True calls in the public caller probe'
require_count 'flyology_simd__backends__native__last_true' 4 \
  "$temporary/mask-position-undefined.txt" \
  'four Native Last_True calls in the public caller probe'
forbid_pattern 'flyology_simd__(first_true|last_true)' \
  "$temporary/mask-position-undefined.txt" \
  'portable mask-position call in the Native caller probe'
require_count 'flyology_simd__backends__native__population_count' 4 \
  "$temporary/mask-position-undefined.txt" \
  'four Native Population_Count calls in the public caller probe'
forbid_pattern 'flyology_simd__population_count' \
  "$temporary/mask-position-undefined.txt" \
  'portable population-count call in the Native caller probe'
for operation in mask_and mask_or mask_xor mask_not test any_true all_true none_true; do
  require_count "flyology_simd__backends__native__${operation}" 4 \
    "$temporary/mask-position-undefined.txt" \
    "four Native ${operation} calls in the public caller probe"
done
require_count 'flyology_simd__backends__native__mask_from_bit_mask' 3 \
  "$temporary/mask-position-undefined.txt" \
  'three out-of-line Native mask-construction calls in the public caller probe'
require_count 'flyology_simd__backends__native__to_bit_mask' 3 \
  "$temporary/mask-position-undefined.txt" \
  'three out-of-line Native mask-conversion calls in the public caller probe'
forbid_pattern 'flyology_simd__(mask_(from_bit_mask|and|or|xor|not)|to_bit_mask|test|any_true|all_true|none_true)' \
  "$temporary/mask-position-undefined.txt" \
  'portable compact-mask call in the Native caller probe'
forbid_pattern 'flyology_simd__(mask_(from_bit_mask|and|or|xor|not)|to_bit_mask|test|any_true|all_true|none_true)' \
  "$temporary/native-undefined.txt" \
  'portable compact-mask call retained in the Native backend object'
require_count 'flyology_simd__backends__native__zero' 10 \
  "$temporary/construction-undefined.txt" \
  'ten Native Zero calls in the public caller probe'
require_count 'flyology_simd__backends__native__splat' 9 \
  "$temporary/construction-undefined.txt" \
  'nine out-of-line Native Splat calls in the public caller probe'
forbid_pattern 'flyology_simd__(zero|splat)' \
  "$temporary/construction-undefined.txt" \
  'portable construction call in the Native caller probe'
for operation in from_lanes to_lanes extract replace; do
  require_count "flyology_simd__backends__native__${operation}" 10 \
    "$temporary/construction-undefined.txt" \
    "ten Native ${operation} calls in the public caller probe"
done
forbid_pattern 'flyology_simd__(from_lanes|to_lanes|extract|replace)' \
  "$temporary/construction-undefined.txt" \
  'portable lane-access call in the Native caller probe'
forbid_pattern 'flyology_simd__(from_lanes|to_lanes|extract|replace)' \
  "$temporary/native-undefined.txt" \
  'portable lane-access call retained in the Native backend object'
require_count 'flyology_simd__backends__native__load_partial' 10 \
  "$temporary/partial-memory-undefined.txt" \
  'ten Native partial-load calls in the public caller probe'
require_count 'flyology_simd__backends__native__store_partial' 10 \
  "$temporary/partial-memory-undefined.txt" \
  'ten Native partial-store calls in the public caller probe'
forbid_pattern 'flyology_simd__(load_partial|store_partial)' \
  "$temporary/partial-memory-undefined.txt" \
  'portable partial-memory call in the Native caller probe'
forbid_pattern 'flyology_simd__(load_partial|store_partial)' \
  "$temporary/native-undefined.txt" \
  'portable partial-memory call retained in the Native backend object'
require_count 'flyology_simd__backends__native__bit_cast' 16 \
  "$temporary/bit-cast-undefined.txt" \
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
require_count '(^|[[:space:]])_?flyology_simd__is_aligned_16$' 1 \
  "$temporary/native-undefined.txt" \
  'only the shared Byte_Array contract predicate remains undefined'
forbid_pattern 'flyology_simd__is_aligned_16__' \
  "$temporary/native-undefined.txt" \
  'typed portable alignment-predicate call retained in the Native backend object'
forbid_pattern 'flyology_simd__splat' \
  "$temporary/native-undefined.txt" \
  'portable Splat call retained in the Native backend object'

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
    require_count "backends__native__${operation_symbol}${symbol_end}" 2 \
      "$caller" "two matching selected reductions in ${lane_kind} ${operation}"
    require_count "backends__native__${combine_symbol}${symbol_end}" 1 \
      "$caller" "one matching selected combine in ${lane_kind} ${operation}"
    require_count "backends__native__${extract_symbol_name}${symbol_end}" 1 \
      "$caller" "one matching selected extraction in ${lane_kind} ${operation}"
    if grep -Eiq "backends__native__${splat_symbol}${symbol_end}" "$caller"; then
        require_count "backends__native__${splat_symbol}${symbol_end}" 2 \
          "$caller" "two matching selected splats in ${lane_kind} ${operation}"
        selected_operation_count=6
    else
        case "$architecture:$lane_kind" in
            aarch64:u8)
                require_count 'dup\.16b' 2 "$caller" \
                  "two inlined byte splats in ${lane_kind} ${operation}"
                ;;
            x86_64:u8)
                require_count 'punpcklbw' 2 "$caller" \
                  "two inlined byte splat expansions in ${lane_kind} ${operation}"
                require_count 'punpcklwd' 2 "$caller" \
                  "two inlined word splat expansions in ${lane_kind} ${operation}"
                require_count 'pshufd' 2 "$caller" \
                  "two inlined dword splat broadcasts in ${lane_kind} ${operation}"
                ;;
            *) echo "missing code-generation requirement: two matching selected splats in ${lane_kind} ${operation}" >&2; exit 1 ;;
        esac
        selected_operation_count=4
    fi
    require_count 'flyology_simd__backends__native__' \
      "$selected_operation_count" "$caller" \
      "only the intended selected operations in ${lane_kind} ${operation}"
    forbid_pattern 'flyology_simd__wide__(native__)?reduce_|flyology_simd__reduce_' \
      "$caller" "Wide dispatcher or portable scalar reduction in ${lane_kind} ${operation}"
done <scripts/probes/wide_reduction_codegen_cases.txt

forbid_pattern 'flyology_simd__wide__(native__)?reduce_|flyology_simd__reduce_' \
  "$temporary/wide-reduction-undefined.txt" \
  'Wide dispatcher or portable scalar reduction retained in caller probe'

case "$architecture" in
    aarch64)
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
        for entry in \
          'shift_left_logical none 16b' 'shift_right_logical none 16b' \
          'shift_left_logical 2 16b' 'shift_right_logical 2 16b' \
          'shift_left_logical 3 8h' 'shift_right_logical 3 8h' \
          'shift_left_logical 4 8h' 'shift_right_logical 4 8h' \
          'shift_left_logical 5 4s' 'shift_right_logical 5 4s' \
          'shift_left_logical 6 4s' 'shift_right_logical 6 4s' \
          'shift_left_logical 7 2d' 'shift_right_logical 7 2d' \
          'shift_left_logical 8 2d' 'shift_right_logical 8 2d'; do
            set -- $entry
            operation=$1
            suffix=$2
            shape=$3
            symbol="flyology_simd__backends__native__${operation}"
            if [ "$suffix" != none ]; then symbol="${symbol}__${suffix}"; fi
            extract_symbol "$symbol" \
              "$temporary/native.txt" "$temporary/${operation}-${suffix}.txt"
            require_pattern "ushl.*${shape}" \
              "$temporary/${operation}-${suffix}.txt" \
              "AArch64 ushl in ${operation} overload ${suffix}"
            forbid_pattern '(^|[[:space:]])bl[[:space:]]|flyology_simd__(zero|shift_(left|right)_logical)' \
              "$temporary/${operation}-${suffix}.txt" \
              "portable or out-of-line helper in ${operation} overload ${suffix}"
        done
        for entry in 'i8x16 16b' 'i16x8 8h' 'i32x4 4s' 'i64x2 2d'; do
            set -- $entry
            lane=$1
            shape=$2
            extract_symbol "native_sra_${lane}" \
              "$temporary/native.txt" "$temporary/${lane}-sar.txt"
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
        for suffix in 2 3 4 5 6 7 8 9 10; do
            extract_symbol "flyology_simd__backends__native__zero__${suffix}" \
              "$temporary/native.txt" "$temporary/construction-zero-${suffix}.txt"
            require_pattern 'movi\.16b.*#0x?0' \
              "$temporary/construction-zero-${suffix}.txt" \
              "AArch64 vector zero construction in overload ${suffix}"
        done
        for entry in '2 16b' '3 8h' '4 8h' '5 4s' '6 4s' '7 2d' '8 2d' '9 4s' '10 2d'; do
            set -- $entry
            suffix=$1
            shape=$2
            extract_symbol "flyology_simd__backends__native__splat__${suffix}" \
              "$temporary/native.txt" "$temporary/construction-splat-${suffix}.txt"
            require_pattern "dup\.${shape}" \
              "$temporary/construction-splat-${suffix}.txt" \
              "AArch64 ${shape} lane broadcast in overload ${suffix}"
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
        extract_symbol 'compare_unordered_f32x4' "$temporary/native.txt" \
          "$temporary/unordered-f32x4.txt"
        extract_symbol 'compare_unordered_f64x2' "$temporary/native.txt" \
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
        require_count 'fadd[[:space:]]+s0' 4 "$temporary/reduce-add-f32x4.txt" \
          'four ascending scalar NEON additions in F32x4 Reduce_Add'
        require_count 'fadd[[:space:]]+d0' 2 "$temporary/reduce-add-f64x2.txt" \
          'two ascending scalar NEON additions in F64x2 Reduce_Add'
        for reduction in reduce-add-f32x4 reduce-add-f64x2; do
            require_pattern 'movi.*v0.*#(0x)?0+([^[:xdigit:]]|$)' \
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
reduce_add_wrap uaddlv.*16b reduce_add_wrap
reduce_min uminv.*16b reduce_min
reduce_max umaxv.*16b reduce_max
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
        require_pattern 'dup.*2d.*v0.*\[1\]' "$temporary/reduce_min_i64.txt" 'NEON signed-64 reduction lane broadcast'
        require_pattern 'cmgt.*2d' "$temporary/reduce_min_i64.txt" 'NEON signed-64 minimum comparison'
        require_pattern 'bit.*16b' "$temporary/reduce_min_i64.txt" 'NEON signed-64 minimum selection'
        require_pattern 'dup.*2d.*v0.*\[1\]' "$temporary/reduce_max_u64.txt" 'NEON unsigned-64 reduction lane broadcast'
        require_pattern 'cmhi.*2d' "$temporary/reduce_max_u64.txt" 'NEON unsigned-64 maximum comparison'
        require_pattern 'bif.*16b' "$temporary/reduce_max_u64.txt" 'NEON unsigned-64 maximum selection'
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
        for select_kind in i8x16 u16x8 i16x8 u32x4 i32x4 u64x2 i64x2 f32x4 f64x2; do
            extract_symbol "native_select_${select_kind}" "$temporary/native.txt" \
              "$temporary/select_${select_kind}.txt"
            require_count '(^|[[:space:]])cmtst(\.(16b|8h|4s|2d))?[[:space:]]+v[0-9]+' 1 \
              "$temporary/select_${select_kind}.txt" \
              "one lane-mask expansion in select_${select_kind}"
            require_count '(^|[[:space:]])bsl(\.16b)?[[:space:]]+v[0-9]+' 1 \
              "$temporary/select_${select_kind}.txt" \
              "one NEON bit selection in select_${select_kind}"
            forbid_pattern '(^|[[:space:]])bl[[:space:]]|flyology_simd__select_value' \
              "$temporary/select_${select_kind}.txt" \
              "out-of-line or portable selection in select_${select_kind}"
        done
        extract_symbol 'native_table_lookup_u8x16' "$temporary/native.txt" "$temporary/table_lookup.txt"
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
            require_pattern 'tbl(\.16b)?[[:space:]]+v[0-9]+,.*\{[[:space:]]*v[0-9]+,[[:space:]]*v[0-9]+[[:space:]]*\},[[:space:]]*v[0-9]+' "$temporary/permute_2_${lane_kind}.txt" "NEON ${lane_kind} public two-source lane permutation"
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
        require_count 'flyology_simd__' 0 \
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
        require_pattern 'flyology_simd__backends__native__native_(add|subtract|multiply|divide)_(f32x4|f64x2)' "$temporary/wide-undefined.txt" 'wide floating arithmetic calls selected 128-bit native leaves'
        require_pattern 'flyology_simd__backends__native__bit_cast' "$temporary/wide-undefined.txt" 'wide F32 bit cast calls the selected 128-bit native leaf'
        require_pattern 'flyology_simd__backends__native__widen_(low|high)' "$temporary/wide-undefined.txt" 'wide byte widening calls selected 128-bit native leaves'
        require_pattern 'flyology_simd__backends__native__narrow_saturate' "$temporary/wide-undefined.txt" 'wide U16 narrowing calls selected 128-bit native leaves'
        require_pattern 'flyology_simd__backends__native__convert_round' "$temporary/wide-undefined.txt" 'wide integer conversion calls selected 128-bit native leaves'
        require_pattern 'flyology_simd__wide__lookup_mechanism__table_lookup_32' "$temporary/wide-undefined.txt" 'wide lookup calls the target-selected lookup mechanism'
        require_pattern 'flyology_simd__backends__native__horizontal_sum' "$temporary/wide-undefined.txt" 'wide exact byte sum calls the selected 128-bit native leaf'
        require_pattern 'flyology_simd__backends__native__(greater|greater_equal|compare_|select_value)' "$temporary/wide-undefined.txt" 'wide byte predicates call selected 128-bit native operations'
        require_count 'flyology_simd__backends__native__((neon_)?add_wrap|native_(add|subtract|multiply|divide)_(f32x4|f64x2)|bit_cast|widen_low|widen_high|narrow_saturate|convert_round|horizontal_sum|greater_bits|greater_equal_bits|compare_(greater(_equal)?_)?i8x16|select_value)|flyology_simd__wide__lookup_mechanism__table_lookup_32' 22 "$temporary/wide-undefined.txt" 'only the intended native primitive classes remain unresolved from the wide probe'
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
        extract_symbol 'construction_codegen_probe__splat_u8' \
          "$temporary/construction-probe.txt" "$temporary/construction-splat-u8.txt"
        require_pattern 'punpcklbw' "$temporary/construction-splat-u8.txt" \
          'inlined x86-64 byte duplication in the U8x16 public caller probe'
        require_pattern 'punpcklwd' "$temporary/construction-splat-u8.txt" \
          'inlined x86-64 word duplication in the U8x16 public caller probe'
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
        for suffix in 2 3 4 5 6 7 8 9 10; do
            extract_symbol "flyology_simd__backends__native__zero__${suffix}" \
              "$temporary/native.txt" "$temporary/construction-zero-${suffix}.txt"
            require_pattern 'pxor' "$temporary/construction-zero-${suffix}.txt" \
              "x86-64 SSE2 zero construction in overload ${suffix}"
        done
        for suffix in 2 3 4 5 6 9; do
            extract_symbol "flyology_simd__backends__native__splat__${suffix}" \
              "$temporary/native.txt" "$temporary/construction-splat-${suffix}.txt"
            require_pattern 'pshufd' "$temporary/construction-splat-${suffix}.txt" \
              "x86-64 SSE2 8/16/32-bit broadcast in overload ${suffix}"
        done
        for suffix in 7 8 10; do
            extract_symbol "flyology_simd__backends__native__splat__${suffix}" \
              "$temporary/native.txt" "$temporary/construction-splat-${suffix}.txt"
            require_pattern 'punpcklqdq' "$temporary/construction-splat-${suffix}.txt" \
              "x86-64 SSE2 64-bit broadcast in overload ${suffix}"
        done
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
            require_pattern 'pxor.*xmm0.*xmm0' "$temporary/${reduction}.txt" \
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
        while read -r symbol output; do
            extract_symbol "$symbol" \
              "$temporary/wide-float-reduction-leaf.txt" \
              "$temporary/$output.txt"
            forbid_pattern '(^|[[:space:]])(call|jmp)[[:space:]]|flyology_simd__wide__reduce_' \
              "$temporary/$output.txt" \
              "portable or out-of-line helper in $output"
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
        require_pattern 'pcmpeqb' "$temporary/native.txt" 'SSE2 byte comparison'
        require_pattern 'pcmpeqw' "$temporary/native.txt" 'SSE2 16-bit comparison'
        require_pattern 'pcmpeqd' "$temporary/native.txt" 'SSE2 32/64-bit comparison composition'
        require_pattern 'pmovmskb' "$temporary/native.txt" 'SSE2 compact mask extraction'
        require_pattern 'paddb' "$temporary/native.txt" 'SSE2 wrapping byte add'
        require_pattern 'paddw' "$temporary/native.txt" 'SSE2 wrapping 16-bit add'
        require_pattern 'paddd' "$temporary/native.txt" 'SSE2 wrapping 32-bit add'
        require_pattern 'paddq' "$temporary/native.txt" 'SSE2 wrapping 64-bit add'
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
multiply_wrap pmullw multiply_wrap|u8_multiply_wrap
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
reduce_add_wrap paddb reduce_add_wrap
reduce_min pminub reduce_min
reduce_max pmaxub reduce_max
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
                forbid_pattern '(^|[[:space:]])call[[:space:]]|flyology_simd__reduce_' \
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
                        require_pattern '(^|[[:space:]])por[[:space:]]' \
                          "$temporary/reduction_${lane_kind}_${operation}.txt" \
                          "SSE2 selected-value merge in ${lane_kind} ${operation}"
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
            extract_symbol "flyology_simd__backends__native__${operation}" \
              "$temporary/native.txt" "$output"
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
            extract_symbol "flyology_simd__backends__native__${operation}" \
              "$temporary/native.txt" \
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
        while read -r suffix lane operation arithmetic expand; do
            symbol="${operation}_saturate${suffix}"
            output="$temporary/${symbol}_${lane}.txt"
            extract_symbol "flyology_simd__backends__native__${symbol}" \
              "$temporary/native.txt" "$output"
            require_pattern "(^|[[:space:]])${arithmetic}[[:space:]]" "$output" \
              "SSE2 packed arithmetic in ${lane} ${operation}_Saturate"
            require_pattern '(^|[[:space:]])p(and|or|xor|andn)[[:space:]]' "$output" \
              "SSE2 overflow or borrow mask in ${lane} ${operation}_Saturate"
            require_pattern "$expand" "$output" \
              "SSE2 complete-lane saturation mask in ${lane} ${operation}_Saturate"
            case "$lane" in
                *64x2)
                    require_pattern '(^|[[:space:]])psrad[[:space:]]' "$output" \
                      "SSE2 replicated 64-bit saturation mask in ${lane} ${operation}_Saturate"
                    ;;
            esac
            if [ "$operation" = subtract ]; then
                require_pattern '(^|[[:space:]])pandn[[:space:]]' "$output" \
                  "SSE2 clamped subtraction selection in ${lane} Subtract_Saturate"
            else
                require_pattern '(^|[[:space:]])por[[:space:]]' "$output" \
                  "SSE2 clamped addition selection in ${lane} Add_Saturate"
            fi
            forbid_pattern '(^|[[:space:]])call|flyology_simd__(add|subtract)_saturate' \
              "$output" "scalar or out-of-line helper in ${lane} ${operation}_Saturate"
        done <<'EOF'
__5 u32x4 add      paddd psrad
__5 u32x4 subtract psubd psrad
__6 i32x4 add      paddd psrad
__6 i32x4 subtract psubd psrad
__7 u64x2 add      paddq pshufd
__7 u64x2 subtract psubq pshufd
__8 i64x2 add      paddq pshufd
__8 i64x2 subtract psubq pshufd
EOF
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
        extract_symbol 'native_table_lookup_u8x16' "$temporary/native.txt" \
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
        require_count 'flyology_simd__backends__native__native_permute_[a-z0-9]+$' 10 \
          "$temporary/permute-undefined.txt" \
          'all ten one-source Native permutation leaves in caller probes'
        require_count 'flyology_simd__backends__native__native_permute_2_[a-z0-9]+$' 10 \
          "$temporary/permute-undefined.txt" \
          'all ten two-source Native permutation leaves in caller probes'
        forbid_pattern 'flyology_simd__backends__native__permute_lanes|flyology_simd__permute_lanes' \
          "$temporary/permute-undefined.txt" \
          'Native dispatcher or portable permutation retained in x86 caller probes'
        while read -r lane_kind lane_shape; do
            for operation in compress expand; do
                output="$temporary/${lane_kind}_${operation}.txt"
                extract_symbol "permute_codegen_probe__${lane_kind}_${operation}" \
                  "$temporary/permute-probe.txt" "$output"
                require_pattern "flyology_simd__backends__native__native_permute_${lane_shape}" \
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
                    require_count "backends__native__native_permute_2_${half_kind}" 2 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "two exact selected permutations in ${vector_kind} ${operation} caller"
                    require_count 'backends__native__native_permute_2_' 2 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "no mismatched permutation in ${vector_kind} ${operation} caller"
                done
                for operation in permute_2 interleave_low interleave_high deinterleave_even deinterleave_odd; do
                    extract_symbol "wide_movement_codegen_probe__${vector_kind}_${operation}" \
                      "$temporary/wide-movement-probe.txt" \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt"
                    require_count "backends__native__native_permute_2_${half_kind}" 4 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "four exact selected permutations in ${vector_kind} ${operation} caller"
                    require_count "$select_leaf" 2 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "two exact selected source choices in ${vector_kind} ${operation} caller"
                    require_count 'backends__native__native_permute_2_' 4 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "no mismatched permutation in ${vector_kind} ${operation} caller"
                    require_count 'backends__native(__select_value|__native_select_)' 2 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "no mismatched source choice in ${vector_kind} ${operation} caller"
                done
                for operation in slide_low slide_high; do
                    extract_symbol "wide_movement_codegen_probe__${vector_kind}_${operation}" \
                      "$temporary/wide-movement-probe.txt" \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt"
                    require_count "backends__native__native_permute_2_${half_kind}" 2 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "two exact selected permutations in ${vector_kind} ${operation} caller"
                    require_count "$select_leaf" 2 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "two exact selected zero-fill choices in ${vector_kind} ${operation} caller"
                    require_count 'backends__native__native_permute_2_' 2 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "no mismatched permutation in ${vector_kind} ${operation} caller"
                    require_count 'backends__native(__select_value|__native_select_)' 2 \
                      "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                      "no mismatched zero-fill choice in ${vector_kind} ${operation} caller"
                    if [ -n "$zero_leaf" ]; then
                        require_count "$zero_leaf" 1 \
                          "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                          "one exact selected zero in ${vector_kind} ${operation} caller"
                        require_count 'backends__native__native_zero_' 1 \
                          "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                          "no mismatched zero constructor in ${vector_kind} ${operation} caller"
                    else
                        require_count '(^|[[:space:]])pxor[[:space:]]+%?xmm0,[[:space:]]*%?xmm0' 2 \
                          "$temporary/wide_movement_${vector_kind}_${operation}.txt" \
                          "exact selector and value zeroing in ${vector_kind} ${operation} caller"
                        require_count 'backends__native__native_zero_' 0 \
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
            require_count '(^|[[:space:]])call' 1 "$temporary/wide_u8_add.txt" 'one isolated AVX2 byte-operation mechanism in wide caller'
            for precision in f32 f64; do
                for operation in add subtract multiply divide min_number max_number; do
                    require_count '(^|[[:space:]])(call|jmp)[[:space:]]' 1 \
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
            require_count '(^|[[:space:]])call' 2 "$temporary/wide_u8_add.txt" 'two inlined SSE2 byte-add leaves in wide caller'
        fi
        if [ "$wide_backend" = composed ]; then
            for precision in f32 f64; do
                for operation in add subtract multiply divide min_number max_number; do
                    require_count '(^|[[:space:]])call' 2 \
                      "$temporary/wide_${precision}_${operation}.txt" \
                      "two selected SSE ${precision} ${operation} leaves in wide caller"
                done
            done
        fi
        require_count '(^|[[:space:]])call' 2 "$temporary/wide_f32_to_u32.txt" 'two SSE F32-to-U32 bit-cast leaves in wide caller'
        require_count '(^|[[:space:]])call' 2 "$temporary/wide_u8_widen.txt" 'two selected byte-widen operations in wide caller'
        require_count '(^|[[:space:]])call' 2 "$temporary/wide_u16_narrow.txt" 'two selected U16-narrow operations in wide caller'
        require_count '(^|[[:space:]])call' 2 "$temporary/wide_i32_to_f32.txt" 'two selected I32-to-F32 conversion operations in wide caller'
        require_count '(^|[[:space:]])call' 1 "$temporary/wide_u8_table_lookup.txt" 'one target-selected 32-lane table-lookup mechanism in wide caller'
        require_count '(^|[[:space:]])call' 2 "$temporary/wide_u8_horizontal_sum.txt" 'two exact byte-sum operations in wide caller'
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
                require_count "backends__native__native_permute_2_${half_kind}" 2 \
                  "$temporary/wide_compact_${lane_kind}_${operation}.txt" \
                  "two selected SSE2 permutations in Wide ${lane_kind} ${operation} caller"
                require_count 'backends__native__native_permute_2_' 2 \
                  "$temporary/wide_compact_${lane_kind}_${operation}.txt" \
                  "no mismatched selected permutation leaf in Wide ${lane_kind} ${operation} caller"
                require_count "$select_leaf" 2 \
                  "$temporary/wide_compact_${lane_kind}_${operation}.txt" \
                  "two selected SSE2 zero-fill selections in Wide ${lane_kind} ${operation} caller"
                require_count 'backends__native(__select_value|__native_select_)' 2 \
                  "$temporary/wide_compact_${lane_kind}_${operation}.txt" \
                  "no mismatched selected zero-fill leaf in Wide ${lane_kind} ${operation} caller"
                if [ -n "$zero_leaf" ]; then
                    require_count "$zero_leaf" 1 \
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
            require_pattern 'flyology_simd__wide__float_avx2_leaf__(add|subtract|multiply|divide|min_number|max_number)' "$temporary/wide-undefined.txt" 'wide floating arithmetic and extrema call isolated AVX2 implementations'
            require_pattern 'flyology_simd__wide__byte_avx2_leaf__(equal|greater_than|select_value)' "$temporary/wide-undefined.txt" 'wide byte predicates call isolated AVX2 implementations'
            forbid_pattern 'flyology_simd__wide__byte_mechanism__' "$temporary/wide-undefined.txt" 'non-AVX2 byte mechanism call retained in the public Wide caller'
        else
            require_pattern 'flyology_simd__backends__native__(u8_)?add_wrap' "$temporary/wide-undefined.txt" 'wide U8 addition calls selected 128-bit native leaves after mechanism inlining'
        fi
        if [ "$wide_backend" = composed ]; then
            require_pattern 'flyology_simd__backends__native__native_(add|subtract|multiply|divide|min_number|max_number)_(f32x4|f64x2)' "$temporary/wide-undefined.txt" 'wide floating arithmetic and extrema call selected 128-bit native leaves'
            require_count 'flyology_simd__backends__native__table_lookup([+-]0x[[:xdigit:]]+)?$' 4 \
              "$temporary/wide-lookup-relocs.txt" \
              'four selected 128-bit table lookups in the composed Wide lookup mechanism'
            require_count 'flyology_simd__backends__native__subtract_wrap([+-]0x[[:xdigit:]]+)?$' 2 \
              "$temporary/wide-lookup-relocs.txt" \
              'two selected 128-bit index adjustments in the composed Wide lookup mechanism'
            require_count 'flyology_simd__backends__native__bitwise_or([+-]0x[[:xdigit:]]+)?$' 2 \
              "$temporary/wide-lookup-relocs.txt" \
              'two selected 128-bit result merges in the composed Wide lookup mechanism'
            require_count 'flyology_simd__(backends__native__)?splat([+-]0x[[:xdigit:]]+)?$' 1 \
              "$temporary/wide-lookup-relocs.txt" \
              'one selected 128-bit 16-filled vector construction in the composed Wide lookup mechanism'
            require_count 'flyology_simd__backends__native__(table_lookup|subtract_wrap|bitwise_or)$|flyology_simd__(backends__native__)?splat$' 4 \
              "$temporary/wide-lookup-undefined.txt" \
              'the four intended selected 128-bit operations remain unresolved from the composed Wide lookup mechanism'
            require_count 'flyology_simd__' 4 \
              "$temporary/wide-lookup-undefined.txt" \
              'only the four intended library operations remain unresolved from the composed Wide lookup mechanism'
            forbid_pattern 'flyology_simd__(wide__)?table_lookup|flyology_simd__wide__native__table_lookup' \
              "$temporary/wide-lookup-undefined.txt" \
              'portable or public Wide table lookup call from the composed lookup mechanism'
        fi
        require_pattern 'flyology_simd__backends__native__bit_cast' "$temporary/wide-undefined.txt" 'wide F32 bit cast calls the selected 128-bit native leaf'
        require_pattern 'flyology_simd__backends__native__widen_(low|high)' "$temporary/wide-undefined.txt" 'wide byte widening calls selected 128-bit native leaves'
        require_pattern 'flyology_simd__backends__native__narrow_saturate' "$temporary/wide-undefined.txt" 'wide U16 narrowing calls selected 128-bit native leaves'
        require_pattern 'flyology_simd__backends__native__convert_round' "$temporary/wide-undefined.txt" 'wide integer conversion calls selected 128-bit native leaves'
        require_pattern 'flyology_simd__wide__lookup_mechanism__table_lookup_32' "$temporary/wide-undefined.txt" 'wide lookup calls the target-selected lookup mechanism'
        require_pattern 'flyology_simd__backends__native__horizontal_sum' "$temporary/wide-undefined.txt" 'wide exact byte sum calls the selected 128-bit native leaf'
        if [ "$wide_backend" = avx2 ]; then
            require_count 'flyology_simd__backends__native__(bit_cast|widen_low|widen_high|narrow_saturate|convert_round|horizontal_sum)|flyology_simd__wide__((byte|float)_avx2_leaf__(add_wrap|equal|equal__2|greater_than|greater_than__2|select_value|select_value__2|add|add__2|subtract|subtract__2|multiply|multiply__2|divide|divide__2|min_number|min_number__2|max_number|max_number__2)|lookup_mechanism__table_lookup_32)' 26 "$temporary/wide-undefined.txt" 'only the intended native primitive classes remain unresolved from the AVX2 wide probe'
        else
            require_count 'flyology_simd__backends__native__((u8_)?add_wrap|native_(add|subtract|multiply|divide|min_number|max_number)_(f32x4|f64x2)|bit_cast|widen_low|widen_high|narrow_saturate|convert_round|horizontal_sum|compare_(equal|greater)(_i8x16)?|native_select_(u8|i8)x16)|flyology_simd__wide__lookup_mechanism__table_lookup_32' 23 "$temporary/wide-undefined.txt" 'only the intended native primitive classes remain unresolved from the composed wide probe'
        fi
        forbid_pattern 'flyology_simd__(wide__)?(add_wrap|add|subtract|multiply|divide|min_number|max_number|bit_cast|widen_(low|high)|narrow_saturate|convert_round|table_lookup|horizontal_sum)' "$temporary/wide-undefined.txt" 'scalar or Wide primitive call from the native wide probe'
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
                require_count 'vzeroupper' 1 "$leaf" \
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
