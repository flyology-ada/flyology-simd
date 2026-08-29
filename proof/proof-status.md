# Proof Status: Flyology_SIMD

The maintained campaign is repo-wide: GNATprove analyzes every production unit
that is inside a declared SPARK boundary, plus a proof-only widest-index
instantiation. `scripts/prove.sh` runs GNATprove FSF 16.1.0 at level 1 with all
available provers, rejects every unproved or justified check and every
`pragma Assume`, treats every warning as an error, and then reruns the Native
SEA traversal independently with the same warning policy.

## Proved and Finalized

- Public specifications are in SPARK except for the two complete-buffer count
  operations whose exact result-overflow boundary is described below, so
  contracts and caller-side checks otherwise remain visible even when an
  implementation ends at a native boundary.
- The portable 128-bit and 256-bit integer families, masks, loads, stores,
  shuffles, conversions, and composition wrappers are proved.
- The Wide exact byte sum retains its codegen-required overflow-check
  suppression, while GNATprove independently proves that same overflow check
  from the two 16-lane sum bounds.
- Scalar and Native byte-array algorithms prove arbitrary Natural bounds,
  traversal, tails, termination, and backend preconditions, except for the two
  exact count-result boundaries described below.
- Scalar and Native floating-array algorithms prove arbitrary Natural bounds,
  traversal, tails, termination, and backend preconditions. Their unrestricted
  scalar floating operations are separately listed below.
- Scalar SEA search is fully in SPARK.
- Native SEA search proves the complete small-input, vector, tail, no-match,
  and match traversal, including the production `Stream_Element_Offset`
  arithmetic near `Stream_Element_Offset'Last`. The raw 16-byte address load is
  isolated behind a proved precondition.
- Runtime and AVX2 dispatch procedures prove their exact `Backend_Unavailable`
  exceptional cases.
- Feature and configuration selection is proved on the selected host backend.
- The AArch64 256-bit byte composition and all selected floating arithmetic
  composition wrappers are proved.

The warning-clean macOS AArch64 run on GNATprove FSF 16.1.0 on 2026-08-25
analyzed 33 units and discharged 4,630 obligations: 1,854 by flow analysis and
2,776 by provers. It contained zero justified checks, zero unproved checks, and
zero `pragma Assume` statements. Linux/x86-64 runs use the same gate in GitHub
Actions; target-specific totals can differ because a different native leaf is
selected.

## Reviewed Proof Boundaries

These exclusions are deliberate and are not justified, suppressed, or counted
as proved:

- Backend register representations, unchecked conversions, compiler
  intrinsics, and `System.Machine_Code` leaves remain native boundaries. Their
  Ada contracts and every portable caller are still analyzed.
- Address-alignment predicates and aligned raw-load/store wrappers remain
  representation boundaries because SPARK does not model the required address
  arithmetic. Unaligned and partial portable memory operations are proved.
- The SEA native loader alone converts the proved array element address to a
  16-byte vector. The search and its arbitrary-bound index arithmetic do not
  use addresses and are fully proved.
- Complete-buffer `Count` and `Count_In_Range` bodies remain exact proof
  boundaries. A `Byte_Array` can contain `Natural'Last + 1` elements while the
  return type is `Natural`; an all-matching input therefore raises the existing
  overflow check. Ada functions cannot declare `Exceptional_Cases`, and a
  length precondition would reject previously valid calls, so proving these
  bodies would require narrowing the public API. `Count` also uses GNAT's
  `__builtin_popcount` intrinsic so optimized AArch64 code retains its NEON
  population count. Differential tests, exhaustive backend mask tests, and
  target code-generation contracts remain checked.
- Root and Wide `F32`/`F64` Add, Subtract, Multiply, Divide, and Reduce_Add
  scalar bodies accept unrestricted IEEE inputs. Proving absence of Ada
  floating overflow or division checks would require public preconditions and
  would narrow the existing API.
- `Narrow_Round (F64x2)` and the `F64x2` to `I64x2`
  `Convert_Truncate_Saturate` scalar bodies cross floating conversion semantics
  that GNATprove does not model precisely enough without narrowing contracts.
  Their public declarations and callers remain in SPARK.
- Runtime and AVX2 functions intentionally raise `Backend_Unavailable` when a
  backend cannot be used. Ada does not permit `Exceptional_Cases` on functions,
  so their function bodies remain dispatch boundaries; the corresponding
  procedures have exact proved exceptional contracts.

Both the broad campaign and focused Native SEA rerun are warning-clean. Exact
compiler diagnostics for proof-required total initialization in generated
array functions and constant-folded search specializations are locally
suppressed; these warning pragmas do not suppress verification conditions.

## Review State

The proof boundary was swept against public compatibility, absence of hidden
copies or allocations, arbitrary array bounds, overflow and range semantics,
termination, native representation assumptions, and unsupported proof claims.
No proof justification or assumption was added to make a check pass. Two exact
count operations use `SPARK_Mode => Off` to preserve their existing overflow
semantics without adding a public input limit; all other exclusions in this
ledger predate or directly isolate native, representation, unsupported
floating-point, or exceptional-function boundaries.
