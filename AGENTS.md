# Repository agent instructions

- Use `gh` outside the sandbox; it does not work inside the sandbox.
- For target-specific SIMD mechanisms, prefer a verified compiler intrinsic.
  If GNAT does not expose a suitable intrinsic, prefer a narrowly isolated Ada
  `System.Machine_Code` assembly leaf over an out-of-line C wrapper.  Keep
  semantics and validation in Ada, differentially test the leaf against the
  scalar backend, and inspect its generated code.
