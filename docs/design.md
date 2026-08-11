# Flyology SIMD design

Status: experimental v0.1 design, 2026-08-10.

## Goals and portability

`flyology_simd` is a standalone, allocation-free Ada library.  It has no
dependency on Flyology or any other crate and deliberately does not provide a
`Flyology` parent unit.  Its root unit is `Flyology_SIMD`.

Portable has three independent meanings here:

1. Public operations have identical semantics on every target.
2. The same source remains usable through the scalar fallback.
3. Verified target backends lower the operations identified by code-generation
   checks to SIMD instruction sequences.

The representation and ABI of vectors are not portable between compilers,
compiler switches, architectures, or enabled instruction sets.  Public vector
and mask types are private.  Values should not cross foreign or persistent ABI
boundaries without being stored as lanes first.

GCC-based GNAT is the initial compiler.  GNAT LLVM is a compatibility target,
not an implemented or verified backend.  SVE, AVX-512, RISC-V V, WebAssembly
SIMD, GPUs, and vendor-intrinsic coverage are outside v0.1.

## v0.1 type and operation scope

The original byte-oriented API established the initial representation, mask,
memory, and backend boundaries. The current type surface contains all signed,
unsigned, and floating 128-bit families. The exact operation matrix and
floating-point contracts are recorded in [api-scope.md](api-scope.md).
AArch64 NEON and the x86-64 SSE2 baseline implement the current operations.
The 256-bit type family and the conversion family are not implemented.

## Normative semantics

- Lane zero is the first logical element loaded from memory.
- Integer wrapping operations are modulo the lane width. Saturating operations
  have `Saturate` in their names.
- A shift count at least the lane width yields zero for logical shifts and sign
  fill for signed arithmetic right shift. Counts are not reduced modulo width.
- Masks express Boolean lane truth.  No all-bits-set representation is public
  or promised.
- `Select_Value (M, If_True, If_False)` selects `If_True` exactly where `M`
  is true.
- `Mask_And`, `Mask_Or`, `Mask_Xor`, and `Mask_Not` combine Boolean lane
  truth without exposing the mask representation.
- Integer `Min`/`Max` use the lane type's signedness. Floating number min/max
  follows the NaN and signed-zero contract in `api-scope.md`.
- Partial loads read exactly `Count` elements and zero the remaining lanes.
  Partial stores write exactly `Count` elements.  A count of zero touches no
  element, including at an otherwise invalid start index permitted by the
  zero-count contract.
- Full and unaligned operations do not require 16-byte alignment. Aligned
  operations have a checked Ada precondition that requires a 16-byte-aligned
  address and a full extent.
- No operation allocates, performs I/O, locks, waits, starts a task, reads
  environment variables, or consults mutable process configuration.
- No build mode enables `-ffast-math` or globally suppresses Ada checks. GNAT
  validity checking is intentionally omitted because it rejects IEEE NaNs.

## Backend boundary

The public value representation is an implementation detail shared by child
units. The root `Flyology_SIMD` body is the full-family scalar authority and
uses simple lane code. `Flyology_SIMD.Backends.Scalar` currently exposes the
byte operations required by the generic byte algorithms.
`Flyology_SIMD.Backends.Native` has the full current operation profile and is
selected by the GPR external `FLYOLOGY_SIMD_ARCH`:

- `scalar`: portable scalar implementation;
- `aarch64`: audited `System.Machine_Code` Advanced SIMD/NEON leaves;
- `x86_64`: full-family SSE2 lowering with explicit scalar composition for
  operations not expressible in SSE2 without changing semantics;
- optional AVX2 whole-buffer objects are compiled separately with `-mavx2`.

The scalar and 128-bit implementations never receive AVX2 compiler switches.
The x86 detector is a baseline Ada machine-code leaf using CPUID and XGETBV.
AVX2 availability requires CPU AVX2 support and OS vector-state support. During
elaboration, XGETBV executes only after CPUID reports AVX and OSXSAVE; no AVX or
AVX2 instruction executes, and no unsupported instruction is attempted.

`Flyology_SIMD.Algorithms.Generic_Bytes` takes a backend operation package as a
generic formal package.  This makes static selection visible to the compiler and
permits inlining through whole-buffer loops.  Named scalar/native
instantiations are supplied.  Runtime selection is performed once in the
non-generic algorithm facade, never once per primitive operation.

Feature information is immutable and computed once during package elaboration,
without a racy writable cache. Runtime selection occurs once per complete
buffer operation, never per vector.

## Memory mechanism

Ordinary public memory operations accept an unconstrained typed array and a
logical start index. Preconditions check a full or partial extent before a
backend can use a machine representation. Partial operations use bounded lane
loops. They never use an out-of-range full load followed by masking.
Address-based overloads are absent from v0.1.

Optimized full-load and compact-mask paths use small target-specific Ada
`System.Machine_Code` leaves.  They read or write exactly one statically sized
128-bit object.  Public array bounds and alignment checks occur before that
mechanism.

## CPU and compiler facts behind the design

GNAT documents loop auto-vectorization separately from explicit vector types;
the former is useful for scalar code but is not an explicit SIMD API.  GCC
vector shifts are undefined for oversized counts, so the public shift contract
must guard counts before using a machine operation.  GCC also warns that runtime
dispatch requires feature-specific files to be compiled separately.  AArch64
always provides Advanced SIMD in the Arm C Language Extensions model.

Matreshka's BSD-3-Clause SIMD packages were reviewed as prior Ada art.  They use
GNAT vector types and imported target intrinsics, but expose ISA-shaped APIs and
their historical AVX detector does not validate OS extended-state support.  No
Matreshka source is copied.  The only SIMD-named crate found in the current
Alire community index was `orka_simd` 1.0.0: it is x86-specific, depends on
`orka_types`, and its recorded repository was unavailable during this review.
It is not used.

## Rejected alternatives

- A `Flyology` parent unit: conflicts when used with Flyology and violates crate
  independence.
- Public GCC vector arrays: exposes unstable representation and permits callers
  to depend on target lane/mask accidents.
- Per-operation runtime dispatch: blocks inlining and adds avoidable branches.
- A large C intrinsic facade: moves Ada policy and contracts across an ABI for
  no semantic benefit.
- Whole-vector tail loads followed by masking: can read beyond the caller's
  declared extent and fail at a page boundary.
- Whole-library `-march=native`, `-mavx2`, `-gnatp`, or `-ffast-math`: makes
  baseline safety or semantic equivalence unverifiable.

## Adding a backend

A backend must implement the current 128-bit operation profile, have no
elaboration side effects, and match scalar results for every tested lane and
mask pattern.
It must add a distinct GPR source selection, target-only compiler switches,
differential tests, assembly checks for required instruction classes and
forbidden leakage, and truthful support-matrix documentation.  Source presence,
cross-compilation, execution, and continuous execution are recorded separately.
