#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
architecture=${1:-scalar}

cd "$project_root"
alr exec -- gprclean -q -r -P tests/tests.gpr \
  "-XFLYOLOGY_SIMD_ARCH=$architecture"
alr exec -- gprbuild -p -P tests/tests.gpr \
  "-XFLYOLOGY_SIMD_ARCH=$architecture" \
  -cargs:Ada -fsanitize=address -fno-omit-frame-pointer \
  -largs -fsanitize=address
ASAN_OPTIONS=detect_leaks=1:abort_on_error=1 ./bin/simd_tests
