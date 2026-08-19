#!/usr/bin/env python3
"""Rewrite canonical SSE2 assembly templates onto register operands.

The generated x86-64 bodies were written against a fixed register convention:
``%%xmm0`` holds the destination and the first source, ``%%xmm1`` the second
source, and ``%%xmm2`` upwards are scratch.  Operands reached the assembly
through memory, which forced every value to spill between operations.

SSE2 instructions are two-operand and read their destination, so the rewrite
ties the result operand to the first input.  That makes the mapping purely
positional -- ``%%xmm0`` is always the result register -- with none of the
liveness tracking the three-operand NEON forms need.
"""

from __future__ import annotations

import re

_ADA_JOIN = '" & ASCII.LF & ASCII.HT & "'
_INSTANTIATION = re.compile(
    r'^(?P<head>\s*function \w+ is new (?P<generic>SSE2_\w+) \()'
    r'(?P<args>.*)(?P<tail>\);)$'
)
_XMM = re.compile(r"%%xmm(\d+)")
_GENERAL = re.compile(r"%%(rax|rcx|rdx|rsi|rdi|r8|r9|eax|ecx|edx)\b")

#  How many canonical registers carry inputs.
SSE_LAYOUT = {
    "SSE2_Binary_128": 2,
    "SSE2_Unary_128": 1,
    "SSE2_Convert_128": 1,
    "SSE2_Convert_Pair_128": 2,
}

#  The shift generic declares its scratch operands itself: %1 already holds the
#  broadcast count, so the template's canonical registers map straight across
#  without the scratch-count variants the other generics use.
SSE_FIXED = {
    "SSE2_Shift_128": {0: 0, 1: 1, 2: 2, 3: 3},
    #  Compare stages Left and Right in %1 and %2 so the two-operand
    #  instructions can consume them, keeps four scratch registers after that,
    #  and takes the sign table as its last input.
    "SSE2_Compare_128": {0: 1, 1: 2, 2: 3, 3: 4, 4: 5, 5: 6, 7: 9},
}

#  A leaf this short is dominated by its call boundary, so it is always worth
#  inlining; a long one would only bloat every call site.
INLINE_INSTRUCTION_LIMIT = 8

_REQUIRED: dict[str, set[int]] = {}


def required_variants(generic: str) -> list[int]:
    return sorted(_REQUIRED.get(generic, {0}))


def _writes(template: str) -> set[int]:
    """Vector registers the template writes.  In AT&T syntax that is the last
    operand of each instruction."""
    written: set[int] = set()
    for line in template.split("\n"):
        _, _, rest = line.strip().partition(" ")
        if not rest:
            continue
        last = rest.split(",")[-1].strip()
        match = _XMM.fullmatch(last)
        if match:
            written.add(int(match.group(1)))
    return written


def plan(template: str, sources: int) -> tuple[str, int, str]:
    """Return the rewritten template, its scratch count and its clobber list."""
    registers = {int(m.group(1)) for m in _XMM.finditer(template)}
    scratch_registers = sorted(r for r in registers if r >= sources)
    #  A template that writes its second source needs a private copy of it:
    #  GCC input operands may share a register with something still live.
    copied = sorted(
        r for r in _writes(template) if 0 < r < sources
    )
    scratch_registers += [f"copy{r}" for r in copied]
    scratch = {register: slot for slot, register in enumerate(scratch_registers, 1)}
    #  Inputs follow the result and every scratch operand.  ``%%xmm0`` is the
    #  result, which the tied input already holds on entry.
    first_input = 1 + len(scratch)

    def replace(match: re.Match) -> str:
        register = int(match.group(1))
        if register == 0:
            return "%0"
        if register < sources:
            if register in copied:
                return f"%{scratch[f'copy{register}']}"
            return f"%{first_input + register}"
        return f"%{scratch[register]}"

    rewritten = _XMM.sub(replace, template)
    #  Seed each private copy before the template runs.
    preamble = [
        f"movdqa %{first_input + register}, %{scratch[f'copy{register}']}"
        for register in copied
    ]
    if preamble:
        rewritten = "\n".join(preamble + [rewritten])
    general = sorted({m.group(1) for m in _GENERAL.finditer(template)})
    clobber = ",".join(general + (["cc"] if general else []))
    return rewritten, len(scratch), clobber


def _unescape(text: str) -> str:
    return text.replace(_ADA_JOIN, "\n")


def _escape(text: str) -> str:
    return text.replace("\n", _ADA_JOIN)


def registerise_instantiations(body: str) -> str:
    """Rewrite the template of every register-operand SSE2 instantiation."""
    out = []
    for line in body.split("\n"):
        match = _INSTANTIATION.match(line)
        generic_name = match.group("generic") if match else None
        if match is not None and generic_name in SSE_FIXED:
            args = match.group("args")
            first, last = args.find('"'), args.rfind('"')
            mapping = SSE_FIXED[generic_name]
            template = _XMM.sub(
                lambda m: f"%{mapping[int(m.group(1))]}",
                _unescape(args[first + 1 : last]),
            )
            out.append(
                match.group("head")
                + args[: first + 1] + _escape(template) + args[last:]
                + match.group("tail")
            )
            continue
        if match is None or generic_name not in SSE_LAYOUT:
            out.append(line)
            continue
        args = match.group("args")
        first, last = args.find('"'), args.rfind('"')
        if first < 0 or last <= first:
            out.append(line)
            continue
        generic = match.group("generic")
        template, scratch, clobber = plan(
            _unescape(args[first + 1 : last]), sources=SSE_LAYOUT[generic]
        )
        rewritten = (
            args[: first + 1] + _escape(template) + args[last:] + f', "{clobber}"'
        )
        head = match.group("head").replace(
            f"is new {generic} (", f"is new {generic}_S{scratch} ("
        )
        out.append(head + rewritten + match.group("tail"))
        if len(template.split("\n")) <= INLINE_INSTRUCTION_LIMIT:
            instantiated = re.match(r"\s*function (\w+) is new", line).group(1)
            out.append(f"   pragma Inline_Always ({instantiated});")
        _REQUIRED.setdefault(generic, set()).add(scratch)
    return "\n".join(_without_duplicate_pragmas(out))


def _without_duplicate_pragmas(lines: list[str]) -> list[str]:
    """Drop a pragma the generator had already emitted for the same leaf."""
    out: list[str] = []
    for line in lines:
        if (
            line.lstrip().startswith("pragma Inline_Always (")
            and out
            and out[-1].strip() == line.strip()
        ):
            continue
        out.append(line)
    return out
