#!/usr/bin/env python3
"""Rewrite canonical AArch64 NEON assembly templates onto register operands.

The generated 128-bit backend bodies were written against a fixed register
convention: ``v0`` holds the destination and the first source, ``v1`` the
second source, and ``v2`` upwards are scratch.  Operands reached the assembly
through memory, which forced every value to spill between operations.

``registerise`` translates one of those templates into GCC operand
placeholders so the same instruction sequence can take and return NEON
registers instead.  It is deliberately conservative: anything it cannot prove
it understands raises, so an unhandled instruction form becomes a generator
error rather than silently wrong code.
"""

from __future__ import annotations

import re

#  Instructions whose destination register is also read.  When such an
#  instruction is the first writer of the destination, the value it expects to
#  find there has to be moved in explicitly, because the destination is now a
#  separate register from the first source.
READ_MODIFY_WRITE = frozenset(
    {
        "bif", "bit", "bsl", "ins", "mla", "mls",
        "xtn2", "sqxtn2", "sqxtun2", "uqxtn2", "fcvtn2",
    }
)

#  Instructions that write no register at all.
NO_DESTINATION = frozenset({"cmp", "str", "stp"})

_LANE = re.compile(r"^v(\d+)(\.[0-9a-z]+(?:\[\d+\])?)$")
_NARROW = re.compile(r"^([bhsdq])(\d+)$")


class TemplateError(RuntimeError):
    pass


def _operands(rest: str) -> list[str]:
    """Split an operand list, keeping ``{v0.16b, v1.16b}`` groups together."""
    out: list[str] = []
    depth = 0
    current = ""
    for character in rest:
        if character == "{":
            depth += 1
        elif character == "}":
            depth -= 1
        if character == "," and depth == 0:
            out.append(current.strip())
            current = ""
            continue
        current += character
    if current.strip():
        out.append(current.strip())
    return out


def registerise(template: str, sources: int, fixed_scratch: int) -> tuple[str, int]:
    """Return the template rewritten onto placeholders, and the scratch used.

    ``sources`` is how many canonical registers carry inputs: 1 for a unary
    leaf (``v0``), 2 for a binary leaf (``v0`` and ``v1``).  ``fixed_scratch``
    is how many scratch operands the enclosing generic always declares, which
    fixes where the inputs start regardless of how many this particular
    template happens to use.  Operand numbering is ``%0`` for the result,
    ``%1`` .. ``%fixed_scratch`` for scratch, then the inputs.
    """
    lines = [line.strip() for line in template.split("\n") if line.strip()]
    scratch: dict[int, int] = {}
    written: set[int] = set()

    def scratch_slot(register: int) -> int:
        if register not in scratch:
            if len(scratch) >= fixed_scratch:
                raise TemplateError(
                    f"template needs more than {fixed_scratch} scratch "
                    f"registers: {template!r}"
                )
            scratch[register] = 1 + len(scratch)
        return scratch[register]

    def source_slot(register: int) -> int:
        #  v0 names the first input until something writes it; after that it
        #  names the result register.
        if register == 0:
            return 0 if 0 in written else _input_slot(0)
        if register < sources:
            return _input_slot(register)
        return scratch_slot(register)

    def destination_slot(register: int) -> int:
        if register == 0:
            return 0
        if register < sources:
            raise TemplateError(
                f"template writes input register v{register}: {template!r}"
            )
        return scratch_slot(register)

    def _input_slot(register: int) -> int:
        #  Inputs follow the result and every scratch operand.  The count is
        #  only final once the whole template has been walked, so inputs are
        #  emitted as markers and renumbered at the end.
        return -(register + 1)

    def rewrite(operand: str, position: str) -> str:
        if operand.startswith("{"):
            inner = operand[1:-1]
            parts = [rewrite(p.strip(), position) for p in inner.split(",")]
            return "{" + ", ".join(parts) + "}"
        lane = _LANE.match(operand)
        if lane:
            register, suffix = int(lane.group(1)), lane.group(2)
            slot = (
                destination_slot(register)
                if position == "destination"
                else source_slot(register)
            )
            return f"%{slot}{suffix}"
        narrow = _NARROW.match(operand)
        if narrow:
            width, register = narrow.group(1), int(narrow.group(2))
            slot = (
                destination_slot(register)
                if position == "destination"
                else source_slot(register)
            )
            return f"%{width}{slot}"
        #  Immediates, general registers and existing placeholders pass through.
        return operand

    out: list[str] = []
    for line in lines:
        mnemonic, _, rest = line.partition(" ")
        operands = _operands(rest)
        if not operands or mnemonic in NO_DESTINATION:
            out.append(line)
            continue
        destination = operands[0]
        lane = _LANE.match(destination) or _NARROW.match(destination)
        if lane is None:
            #  A general-purpose destination such as ``umov %w0, v0.h[0]``.
            out.append(
                mnemonic
                + " "
                + ", ".join(
                    [destination]
                    + [rewrite(o, "source") for o in operands[1:]]
                )
            )
            continue
        register = int(lane.group(1) if _LANE.match(destination) else lane.group(2))
        if mnemonic in READ_MODIFY_WRITE and register == 0 and 0 not in written:
            out.append(f"mov %0.16b, %{_input_slot(0)}.16b")
            written.add(0)
        sources_text = [rewrite(o, "source") for o in operands[1:]]
        destination_text = rewrite(destination, "destination")
        written.add(register)
        out.append(mnemonic + " " + ", ".join([destination_text] + sources_text))

    #  Inputs sit after the result and the generic's full scratch allowance.
    first_input = 1 + fixed_scratch
    text = "\n".join(out)
    for register in range(sources):
        text = text.replace(f"%{_input_slot(register)}", f"%{first_input + register}")
        text = text.replace(f"%b{_input_slot(register)}", f"%b{first_input + register}")
    return text, len(scratch)


#  How many canonical registers carry inputs, and how many scratch operands the
#  generic always declares.  A generic is only listed once it takes register
#  operands; anything absent is left on the address model untouched.
#  Each generic is emitted once per scratch-register count that its
#  instantiations actually need, and an instantiation names the variant that
#  fits it.  Scratch operands are early-clobber, so they only constrain
#  allocation at the assembly itself, but demanding registers that the template
#  never uses still narrows the allocator inside a hot loop.
NEON_LAYOUT = {
    "NEON_Binary_128": 2,
    "NEON_Unary_128": 1,
    "NEON_Convert_128": 1,
    "NEON_Convert_Pair_128": 2,
}
MAXIMUM_SCRATCH = 8


def plan(template: str, sources: int) -> tuple[str, int]:
    """Rewrite a template using exactly as many scratch registers as it needs."""
    used = registerise(template, sources=sources, fixed_scratch=MAXIMUM_SCRATCH)[1]
    return registerise(template, sources=sources, fixed_scratch=used)

_ADA_JOIN = '" & ASCII.LF & ASCII.HT & "'
_INSTANTIATION = re.compile(
    r'^(?P<head>\s*function \w+ is new (?P<generic>NEON_\w+) \()'
    r'(?P<args>.*)(?P<tail>\);)$'
)


def _unescape(text: str) -> str:
    return text.replace(_ADA_JOIN, "\n")


def _escape(text: str) -> str:
    return text.replace("\n", _ADA_JOIN)


def registerise_instantiations(body: str) -> str:
    """Rewrite the assembly template of every register-operand instantiation."""
    out = []
    for line in body.split("\n"):
        match = _INSTANTIATION.match(line)
        if match is None or match.group("generic") not in NEON_LAYOUT:
            out.append(line)
            continue
        args = match.group("args")
        first, last = args.find('"'), args.rfind('"')
        if first < 0 or last <= first:
            out.append(line)
            continue
        generic = match.group("generic")
        template, scratch = plan(
            _unescape(args[first + 1 : last]), sources=NEON_LAYOUT[generic]
        )
        rewritten = args[: first + 1] + _escape(template) + args[last:]
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


#  Populated as instantiations are rewritten, so the helper emitter knows which
#  variants to declare.
#  A leaf this short is dominated by its call boundary, so it is always worth
#  inlining; a long one would only bloat every call site.
INLINE_INSTRUCTION_LIMIT = 8

_REQUIRED: dict[str, set[int]] = {}


def required_variants(generic: str) -> list[int]:
    return sorted(_REQUIRED.get(generic, {0}))
