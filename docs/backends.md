# Backend and compiler support

Support claims distinguish source implementation, compilation, execution, and
continuous execution.  A source file alone is not a support claim.

| Backend | Implemented | Compiled locally | Executed locally | CI configured |
|---|---:|---:|---:|---:|
| Scalar fallback | yes | yes | yes, including ASan | Linux x86-64 and macOS AArch64 |
| AArch64 NEON full 128-bit family | yes | yes | yes, macOS AArch64 | macOS AArch64 |
| x86-64 SSE2 byte optimization, full-family fallback | provisional | no (non-x86 host) | no | Linux x86-64 |
| x86-64 AVX2 algorithms | yes | no (non-x86 host) | no | Linux x86-64 with runtime gate |

Local evidence is GNAT FSF 16.1.0 on Darwin AArch64, model `Mac15,9`.
GCC-based GNAT is required initially.  No other GNAT version is advertised as
verified.  GNAT LLVM is an explicit compatibility target, not an implemented or
tested backend, because the available toolchain does not provide equivalent
verified intrinsic/assembly lowering.

AArch64 Advanced SIMD is architecturally available and no runtime NEON probe is
needed. Its integer and floating operation classes are differentially executed
and assembly-audited locally; 64-bit integer multiply, reductions, mask select,
and unordered floating comparison currently use documented scalar composition
where Advanced SIMD lacks the direct operation or the leaf is not yet stable.
x86-64 SSE2 is the baseline. AVX2 is a separate object configuration:
its availability gate checks AVX and OSXSAVE, verifies XCR0 enables XMM/YMM
state, and then checks CPUID leaf 7 AVX2.  Detection and SSE2 objects are built
with AVX disabled.  Optional instructions are not executed during elaboration.

The workflow contains no `continue-on-error`.  Hosted CI should only be called
green after an actual workflow run; this repository has not yet had one.
