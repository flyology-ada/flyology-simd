# Flyology SIMD design

Status: experimental v0.1 design, 2026-08-12.

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
The `Flyology_SIMD.Wide` child package supplies an initial profile for all ten
corresponding 256-bit value types. Its operation surface is narrower than the
complete 128-bit surface.
The 128-bit API implements lane-preserving bit casts, adjacent integer
widening and narrowing, exact finite `F32x4` to `F64x2` widening, and rounded
`F64x2` to `F32x4` narrowing. It also converts 32- and 64-bit signed and
unsigned integer lanes to the corresponding floating family.
Floating lanes convert back to same-width signed or unsigned integers with
explicit truncation and saturation semantics.
Signed and unsigned integer vectors of each lane width convert in both
directions with explicit saturation semantics.
All ten value families provide stable mask compression and
expansion. These operations retain fixed-width results and do not allocate a
variable-length container.
The byte family includes a 16-entry table lookup. The public zero result for
an out-of-range index is independent of a target instruction's behavior.
The initial Wide profile includes two-source lane maps, lane-preserving bit
casts, widening, narrowing, and numeric conversion. It omits table lookup.

## Normative semantics

Floating-to-integer conversion is a total operation. The public name
`Convert_Truncate_Saturate` states both steps: truncate a finite input toward
zero, then clamp it to the integer range. NaN maps to zero. This design avoids
a hidden range precondition. Some target instructions return a fixed integer
for an out-of-range input. The public contract does not expose that
instruction-specific result.

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
- `First_True` and `Last_True` return the lane-count value when no lane is
  true. If the mask contains a true lane, the result is a valid lane index.
- `Compress` packs true-mask lanes toward lane 0 in source order and zero-fills
  the remaining result lanes. `Expand` consumes packed low lanes into true
  mask positions and zero-fills false positions. Moved lane bits do not
  change. Floating fill lanes contain positive zero.
- `Table_Lookup` uses each unsigned byte index independently. Indexes from 0
  through 15 select table lanes. Larger indexes return zero.
- `Make_Lane_Map` accepts only valid lane indexes. `Permute_Lanes` reads one
  source vector through that reusable map. Repeated selectors broadcast a
  source lane. Floating lane encodings remain unchanged.
- `Make_Two_Source_Lane_Map` accepts only typed left-or-right lane selectors.
  The three-argument `Permute_Lanes` overload selects independently from two
  source vectors. Repeated selectors broadcast a source lane, and moved lane
  encodings remain unchanged.
- Lane-slide counts are in lanes. `Slide_Lanes_Toward_Low` fills vacated
  high-index lanes with zero. `Slide_Lanes_Toward_High` fills vacated
  low-index lanes with zero. A count equal to or greater than the lane count
  returns zero.
- Integer `Min`/`Max` use the lane type's signedness. Floating number min/max
  follows the NaN and signed-zero contract in `api-scope.md`.
- Floating minimum-number and maximum-number reductions use an ascending-lane
  left fold. The fold order is part of the portable contract.
- Partial loads read exactly `Count` elements and zero the remaining lanes.
  Partial stores write exactly `Count` elements.  A count of zero touches no
  element, including at an otherwise invalid start index permitted by the
  zero-count contract.
- Full and unaligned operations have no alignment requirement. Aligned
  operations have a checked Ada precondition and require a full extent.
  They require 16-byte alignment for 128-bit values and 32-byte alignment for
  Wide values.
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
- `aarch64`: `System.Machine_Code` Advanced SIMD/NEON leaves that have
  differential tests and focused code-generation checks;
- `x86_64`: full-family SSE2 lowering with explicit scalar composition for
  operations not expressible in SSE2 without changing semantics;
- optional AVX2 whole-buffer objects are compiled separately with `-mavx2`.

`Flyology_SIMD.Wide` is the scalar authority for the initial 256-bit profile.
Its private values currently contain two 128-bit parts.
`Flyology_SIMD.Wide.Native` composes selected 128-bit native operations across
those parts. This boundary does not expose the pair, promise a stable ABI, or
claim an AVX2-specific 256-bit leaf or instruction sequence.
Wide bit casts compose two same-shape 128-bit bit casts. Wide two-source lane
maps use fixed-width Ada composition through the selected 128-bit lane access
operations; they have no dedicated 256-bit instruction claim.
Wide conversion operations compose the corresponding 128-bit conversion
operations. Widening applies the 128-bit `Widen_Low` and `Widen_High`
operations to the selected private part. Narrowing converts both private parts
of each Wide input. Same-width numeric conversions apply one 128-bit operation
to each private part.

The AArch64 backend lowers lane permutation, lane slides, widening, narrowing,
mask compression, mask expansion, and numeric conversion through verified NEON
assembly leaves. The x86-64 SSE2 backend
uses immediate byte-shift leaves for lane slides and currently composes these
conversion operations from the scalar authority.
It also composes variable lane permutation, mask compression, and mask
expansion because SSE2 has no indexed-byte table instruction.
This preserves the contract but does not claim an SSE2 instruction sequence
for those operations.

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

Optimized 128-bit full-load and compact-mask paths use small target-specific Ada
`System.Machine_Code` leaves.  They read or write exactly one statically sized
128-bit object.  Public array bounds and alignment checks occur before that
mechanism.

Wide full and partial operations apply the corresponding rules to 256 bits of
elements. Wide aligned operations require 32-byte alignment.

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
