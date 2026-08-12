# Backend and compiler support

Support claims distinguish source implementation, compilation, execution, and
continuous execution.  A source file alone is not a support claim.

| Backend | Implemented | Compiled evidence | Executed evidence | CI configured |
|---|---:|---:|---:|---:|
| Scalar fallback | yes | yes | yes, including ASan | Linux x86-64 and macOS AArch64 |
| AArch64 NEON full 128-bit family | yes | yes | yes, macOS AArch64 | macOS AArch64 |
| x86-64 SSE2 full 128-bit family | yes | Linux x86-64 | differential + ASan, Linux x86-64 | Linux x86-64 |
| x86-64 AVX2 algorithms | yes | Linux x86-64 | differential, Linux x86-64 AVX2 | Linux x86-64 with runtime gate |
| x86-64 AVX2 Wide `U8x32` lookup | yes | Linux x86-64 | differential + code generation, Linux x86-64 AVX2 | Linux x86-64, static selection |

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
64-bit conversions use comparisons and bit selection. The 16-entry byte-table
lookup uses one-register `tbl`. The Wide 32-entry lookup uses two-register
`tbl`. Both forms produce zero for an out-of-range index. Lane slides use `ext`
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
with baseline-safe code. Detection and SSE2 objects are built with AVX disabled.
AVX and AVX2 instructions are absent outside the optional AVX2 algorithm object
and the optional Wide lookup object. The public AVX2 algorithm package is a
baseline-safe wrapper that rejects an unavailable backend before it enters that
private object.

Wide values have a private pair-of-128 implementation.
`Flyology_SIMD.Wide.Native` composes selected 128-bit backend operations on
the two parts for every operation except the optional x86-64 AVX2 `U8x32`
table lookup. No other Wide operation has a 256-bit instruction claim. The
current Wide tests cover fixed vectors and 128 deterministic pseudorandom inputs
for all ten value families. They compare every current Native operation group
with the scalar authority, cover all partial-memory counts, and exercise
floating reduction order, signed zero, and special lane encodings.
Wide bit casts compose two selected 128-bit bit casts. Wide two-source lane
maps use fixed-width scalar composition through selected lane access
operations. The differential tests check the scalar and Native maps for all
ten value types and check floating special encodings bit for bit.
Wide conversion operations compose the corresponding selected 128-bit
operations. For each of the 46 Wide conversion overloads, tests use fixed
vectors and 32 deterministic pseudorandom inputs. They compare scalar and
Native results with results from the 128-bit authority. Direct floating-point
edge cases cover signed zeros,
infinities, quiet and signaling NaNs, subnormals, halfway rounding, overflow,
and explicit floating-to-integer outcomes in both private parts. Caller-level
code-generation probes require two selected 128-bit calls for representative
widening, narrowing, and numeric
conversion operations. The project does not claim a 256-bit instruction
sequence.
The default Wide 32-entry lookup uses composed target code. On AArch64, it
applies one two-register `tbl` leaf to each private index part. On scalar and
x86-64 targets, the composed selection uses the scalar authority. The optional
x86-64 AVX2 selection uses one separately compiled 256-bit implementation
subprogram. Tests compare
fixed, all-index, and deterministic pseudorandom cases with an independent
lane oracle for each selection. The x86-64 code-generation gate requires one
mechanism call from the public caller. For the AVX2 selection, the isolated
subprogram must contain `vpshufb`, `vperm2i128`, `vpsubusb`, and `vzeroupper`.
Baseline objects must remain free of AVX instructions.

`FLYOLOGY_SIMD_WIDE_BACKEND` accepts `composed`, the default, or `avx2`.
The `avx2` value selects the optional implementation subprogram only with
`FLYOLOGY_SIMD_ARCH=x86_64` and `FLYOLOGY_SIMD_AVX2=enabled`. The build rejects
other configurations. This is compile-time selection without a feature check.
The application must deploy that binary only where CPUID reports the AVX,
AVX2, and OSXSAVE bits, and XCR0 enables XMM and YMM register state. This rule
differs from `Algorithms.AVX2`, which checks these conditions before it enters
an optional whole-buffer object.
The Wide exact byte sum adds two selected 128-bit `Horizontal_Sum` results.
Fixed-vector and deterministic pseudorandom tests compare scalar and Native
results with an independent lane oracle. AArch64 and x86-64 caller-level
code-generation checks require two calls to the target-selected 128-bit
`Horizontal_Sum` operation.

The workflow contains no `continue-on-error`. Public hosted CI has executed
earlier commits successfully. The support page links to the current workflow
result; new commits do not have hosted evidence until their runs finish.
