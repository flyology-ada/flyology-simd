#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
architecture=${1:-scalar}
leak_detection=1
if [ "$(uname -s)" = Darwin ]; then
  # LeakSanitizer shutdown hangs with the locally verified FSF GNAT runtime;
  # AddressSanitizer bounds/use-after-free checks remain active.
  leak_detection=0
fi

cd "$project_root"
alr exec -- gprclean -q -r -P tests/tests.gpr \
  "-XFLYOLOGY_SIMD_ARCH=$architecture"
alr exec -- gprbuild -p -P tests/tests.gpr \
  "-XFLYOLOGY_SIMD_ARCH=$architecture" \
  -cargs:Ada -fsanitize=address -fno-omit-frame-pointer \
  -largs -fsanitize=address
ASAN_OPTIONS=detect_leaks=$leak_detection:abort_on_error=1 ./bin/simd_tests
ASAN_OPTIONS=detect_leaks=$leak_detection:abort_on_error=1 ./bin/family_tests
ASAN_OPTIONS=detect_leaks=$leak_detection:abort_on_error=1 ./bin/conversion_tests
ASAN_OPTIONS=detect_leaks=$leak_detection:abort_on_error=1 ./bin/guard_page_tests
