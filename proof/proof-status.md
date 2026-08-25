# Proof Status: Flyology_SIMD
<!-- Reflect the top-level goal given. Items in the list below are moved from
     Not Started to In Progress to Reviewed and finally to Proved and Finalized. -->

Initial campaign targets the production index arithmetic used by arbitrary-bound
`Ada.Streams.Stream_Element_Array` searches and the direct Scalar SEA entry
point. Native address loads and target-specific SIMD leaves remain outside this
first proof boundary.

## Proved and Finalized
<!-- Before marking an item complete here, follow the Widen Scope step
     (Strategic Loop Step 5) in workflow.md in the /gnatprove Skill.
     Remember: changes to types used by or called subprograms in a given
     subprogram may cause it to regress to an unproved state. Reproving at the
     wider scope is thus a critical means to detect these situations. -->

- [x] `Flyology_SIMD.Index_Arithmetic.Index_At`
  - The SEA specialization proves six prover checks plus termination, including
    exact-result, contract arithmetic, and conversion checks. The widest-index
    fallback is outside this SEA-specialized proof boundary.
- [x] `Flyology_SIMD.Algorithms.Stream_Element_Arrays.Scalar.Find_First_Of`
  - The production unit is flow analyzed with zero errors, warnings, checks,
    or pragma Assume statements, and its implicit termination aspect is proved.
- [x] Widened suite
  - GNATprove FSF 16.1.0, `--mode=all --level=1 -j0 --output-header
    --report=all --warnings=error -U -f`: 8/8 aggregate checks proved, zero
    justified or unproved checks, zero warnings, and zero pragma Assume
    statements.

## Reviewed
<!-- Before marking an item complete here, review it following the Review
     step (Strategic Loop Step 4) in workflow.md in the /gnatprove Skill -->


## In Progress
<!-- A subagent executes the Tactical Loop for the subprogram below.
     It should update this section as it works. -->


## Not Started
<!-- Whenever a subprogram is added (due to refactoring) or discovered
     during assessment (Strategic Loop Steps 1-2), list it here so it
     is not forgotten. -->

## Discovered Obligations
