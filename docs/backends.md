# Backend and compiler support

Support claims distinguish source implementation, compilation, execution, and
continuous execution.  A source file alone is not a support claim.

| Backend | Implemented | Compiled evidence | Executed evidence | CI configured |
|---|---:|---:|---:|---:|
| Scalar fallback | yes | yes | yes, including ASan | Linux x86-64 and macOS AArch64 |
| AArch64 NEON full 128-bit family | yes | yes | yes, macOS AArch64 | macOS AArch64 |
| x86-64 SSE2 full 128-bit family | yes | Linux x86-64 | differential + ASan, Linux x86-64 | Linux x86-64 |
| x86-64 AVX2 algorithms | yes | Linux x86-64 | differential, Linux x86-64 AVX2 | Linux x86-64 with runtime gate |

The initial `Flyology_SIMD.Wide` profile is compiled and executed on the local
Darwin AArch64 development host. The workflow is configured to run
`wide_tests` on its Linux x86-64 and macOS AArch64 jobs. This statement is a
workflow-configuration claim, not a hosted result for an unpushed commit.

Executed evidence uses GNAT FSF 16.1.0 on Darwin AArch64 and Linux x86-64.
GCC-based GNAT is required initially.  No other GNAT version is advertised as
verified.  GNAT LLVM is an explicit compatibility target, not an implemented or
tested backend, because the available toolchain does not provide equivalent
verified intrinsic/assembly lowering.

AArch64 Advanced SIMD is architecturally available and no runtime NEON probe is
needed. Its integer and floating operation classes have differential tests and
focused code-generation checks. Integer widening and narrowing use `uxtl`,
`sxtl`, `xtn`, `uqxtn`, `sqxtn`, and `sqxtun` instruction families. Floating
widening uses `fcvtl`, floating narrowing uses `fcvtn`, integer-to-floating
conversion uses `scvtf` and `ucvtf`, and floating-to-integer conversion uses
`fcvtzs` and `fcvtzu`. Same-width signed/unsigned conversion uses signed
maximum and unsigned minimum instructions for 8-, 16-, and 32-bit lanes. The
64-bit conversions use comparisons and bit selection. Byte-table lookup uses
`tbl`, including its zero result for indexes above 15. Lane slides use `ext`
with a zero vector and an immediate byte offset. Reusable lane maps contain
expanded byte indexes, so each AArch64 `Permute_Lanes` overload uses `tbl`
after map construction. Two-source maps use a two-register `tbl` table.
`Compress` and `Expand` construct a byte-index map from the mask and then use
`tbl` for every value family.
`Multiply_Wrap`, `Select_Value`,
`Reduce_Add_Wrap`, `Reduce_Min`, and `Reduce_Max` use scalar composition for
`U64x2` and `I64x2`. `Select_Value`, `Reduce_Add`, and `Unordered` use scalar
composition for `F32x4` and `F64x2`. Floating minimum-number and
maximum-number reductions use scalar Advanced SIMD leaves in ascending lane
order.

x86-64 SSE2 is the baseline. SSE2 implements vector arithmetic, bitwise
operations, shifts, comparisons, compact masks, selection, shuffles, and full
memory operations across every 128-bit integer and floating family. Lane
slides use the immediate-byte `psrldq` and `pslldq` instructions. Saturating
arithmetic uses scalar composition for 32- and 64-bit lanes. `Reduce_Min` and
`Reduce_Max` use scalar composition for all integer families. Except for the
byte exact-sum implementation, integer `Reduce_Add_Wrap` also uses scalar
composition. Floating `Min_Number`, `Max_Number`, and `Reduce_Add` use scalar
composition. Floating minimum-number and maximum-number reductions also use
scalar composition. The current bit casts, widening, narrowing, and numeric
conversion operations use scalar composition on x86-64. These operations are
implemented and differentially tested, but they do not yet have an SSE2
code-generation claim. The x86-64 byte-table lookup and one-source or
two-source variable lane permutations use scalar composition because SSE2 has
no equivalent indexed byte-table instruction. Mask compression and expansion
also use scalar composition on x86-64.
AVX2 is a separate object configuration:
its availability gate checks AVX and OSXSAVE, verifies XCR0 enables XMM/YMM
state, and then checks CPUID leaf 7 AVX2.  The immutable result is computed once
with baseline-safe code. Detection and SSE2 objects are built with AVX disabled;
AVX and AVX2 instructions are absent outside the AVX2-only object. The public
AVX2 package is a baseline-safe wrapper that rejects an unavailable backend
before entering that private object.

Wide values have a private pair-of-128 implementation.
`Flyology_SIMD.Wide.Native` composes selected 128-bit backend operations on
the two parts. It does not yet contain an AVX2-specific 256-bit leaf, and the
code-generation checks make no 256-bit instruction claim. The current Wide
tests cover fixed vectors and 128 deterministic pseudorandom inputs for all ten
value families. They compare every current Native operation group with the
scalar authority, cover all partial-memory counts, and exercise floating
reduction order, signed zero, and special lane encodings.

The workflow contains no `continue-on-error`. Public hosted CI has executed
earlier commits successfully. The support page links to the current workflow
result; new commits do not have hosted evidence until their runs finish.
