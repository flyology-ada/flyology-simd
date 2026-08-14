# Contributing

Run `git diff --check`, the scalar suite, the native suite on your architecture,
and `scripts/check_codegen.sh` before proposing changes.  Tests use a printed,
fixed random seed; preserve reproducibility or print any replacement seed.

## Adding a backend

1. Add one source directory containing bodies for `Backends.Native` and
   `Features`; keep the public vector representation private.
2. Implement semantics, validation, and tail policy in Ada.  Prefer a verified
   intrinsic.  If GNAT has no suitable intrinsic, isolate a minimal
   `System.Machine_Code` assembly leaf; do not introduce an out-of-line C policy
   wrapper.
3. Compile optional ISA objects separately.  Never apply an optional ISA switch
   to feature detection, scalar code, the baseline backend, or consumers.
4. Differentially compare every operation and representative algorithm with the
   scalar authority, including all lanes, every tail, deterministic random data,
   and unavailable-backend rejection.
5. Add narrow assembly checks for required instruction classes, absence of
   scalarization, and forbidden ISA leakage.
6. Update the support table separately for implemented, compiled, executed, and
   continuously executed status.

New vector families need explicit conversion, bit-cast, shift, overflow,
narrowing, and floating-point semantics before their types become public. Run
both `simd_tests` and `family_tests`; generated family files are reproduced by
`scripts/generate_full_family.py`, `scripts/generate_backends.py`, and
`scripts/generate_conversion_tests.py`, in that order.

The generated `U8x16` value-operation caller probe and its 26-operation
manifest are reproduced by `scripts/generate_u8_value_probe.py`.
The generated 128-bit integer-reduction caller probe and its 24-operation
manifest are reproduced by `scripts/generate_integer_reduction_probe.py`.
The generated fixed-width floating binary-operation caller probe and its
12-operation manifest are reproduced by `scripts/generate_float_binary_probe.py`.
The generated complete 128-bit memory caller probe and its 60-operation
manifest are reproduced by `scripts/generate_complete_memory_probe.py`.
The generated fixed-width comparison and selection caller probe and its
62-operation manifest are reproduced by `scripts/generate_comparison_probe.py`.
The generated fixed-width wrapping-arithmetic caller probe and its
24-operation manifest are reproduced by
`scripts/generate_wrapping_arithmetic_probe.py`.
The generated fixed-width lane-arrangement caller probe and its 50-operation
manifest are reproduced by `scripts/generate_lane_arrangement_probe.py`.
The generated fixed-width bitwise caller probe and its 32-operation manifest
are reproduced by `scripts/generate_bitwise_probe.py`.
The generated fixed-width integer `Min`/`Max` probe and its 16-operation
manifest are reproduced by `scripts/generate_integer_minmax_probe.py`.
The generated Wide integer-reduction caller probe and its 24-operation
manifest are reproduced by `scripts/generate_wide_reduction_probe.py`.
The generated Wide construction and lane-access caller probe and its
60-operation manifest are reproduced by
`scripts/generate_wide_construction_probe.py`.
The generated Wide comparison and selection caller probe and its 62-operation
manifest are reproduced by `scripts/generate_wide_comparison_probe.py`.
