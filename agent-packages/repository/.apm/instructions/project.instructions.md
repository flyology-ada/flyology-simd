---
description: Preserve Flyology SIMD's project-specific repository rules and verification workflow.
---

# Repository agent instructions

## GNATdoc

Keep GNATdoc entity comments after their declarations and pass
`--style=gnat` explicitly. This repository-specific trailing convention
overrides the shared leading default.

- Use `gh` outside the sandbox; it does not work inside the sandbox.
- For target-specific SIMD mechanisms, prefer a verified compiler intrinsic.
  If GNAT does not expose a suitable intrinsic, prefer a narrowly isolated Ada
  `System.Machine_Code` assembly leaf over an out-of-line C wrapper.  Keep
  semantics and validation in Ada, differentially test the leaf against the
  scalar backend, and inspect its generated code.
- Keep handwritten Ada source to 110 columns.  After editing Ada, run
  `gnatformat -P flyology_simd.gpr <handwritten-source-files>`; the root project
  owns the formatter settings.  Change generators rather than running
  GNATformat on generated Ada independently.

## Documentation claims

- Distinguish identical semantics, scalar source portability, and efficient
  target-specific code generation.
- Distinguish implemented, compiled, executed, and continuously tested support.
- Keep alignment, valid extent, tail access, NaN, signed-zero, and conversion
  conditions next to the operation that they qualify.
- State whether a choice occurs at compile time or once at a whole-buffer
  algorithm boundary.
- Treat the scalar backend and executable differential tests as the authority
  for operation semantics.
- Label benchmark observations with the host, compiler, switches, method, and
  measurement date. Do not generalize one host result.
- Do not describe a private vector representation or ABI as portable.

## Releases

- Publish `flyology_simd` through an immutable annotated tag named
  `flyology_simd/v<version>`, for example `flyology_simd/v0.1.0`.
- Before tagging, set the root `alire.toml` to the exact stable version,
  replace inappropriate `-dev` dependency constraints with stable constraints,
  and run the required checks plus `alr show`. The manifest must declare
  `name = "flyology_simd"` and the same version as the tag.
- Create and push the tag only after committing the release-ready manifest:

  ```sh
  git tag -a flyology_simd/v<version> -m "Release flyology_simd <version>"
  git push origin refs/tags/flyology_simd/v<version>
  ```

- Never move, replace, or reuse a published release tag. Put the next
  development-version change in a later commit.
