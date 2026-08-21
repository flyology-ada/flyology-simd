# Contributing

Run `git diff --check`, the scalar suite, the native suite on your architecture,
and `python3 scripts/check_codegen.py` before proposing changes.  Tests use a printed,
fixed random seed; preserve reproducibility or print any replacement seed.

Every public fixed-width and Wide overload is assigned to one family in
`scripts/simd_coverage.toml`. The inventory records semantic, generated-code,
API-documentation, and teaching evidence. It also owns every generated caller
probe, manifest row count, static checker, documentation classification, and
accepted gap together with its deterministic closure. Reproduce every probe and
`docs/coverage.md`, run the registered static checks, and enforce the finite
zero-gap definition of done with:

```sh
python3 scripts/check_simd_coverage.py \
  --generate-probes --check-static --write-report --require-complete
```

Use `--check-probes` instead of `--generate-probes` for a read-only freshness
check. CI runs the generating zero-gap command before its clean-tree check. It
fails when a probe generator or manifest is not registered, a manifest has the
wrong number of unique rows, the declared gap set is nonempty, documentation
classification lacks its registered checker, teaching evidence omits an
operation, or a family that requires an executable example does not name one.

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

Generated caller-probe ownership is declared only in the `[[probe]]` entries of
`scripts/simd_coverage.toml`; do not maintain a second handwritten list here.
The generated probe ledger in `docs/coverage.md` is the human-readable index.
