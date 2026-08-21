#!/usr/bin/env python3
"""Primitives used by the generated-code checker.

Patterns are evaluated by ``grep -E`` to retain the checker's established
POSIX extended-regular-expression semantics.
"""

from __future__ import annotations

import re
import shutil
import subprocess
from pathlib import Path


class CodegenError(RuntimeError):
    """A generated-code contract was not satisfied."""


class Checker:
    """Evaluate code-generation assertions over disassembly text files."""

    REGISTER_OPERAND_FAMILIES = {
        "u8",
        "i8",
        "u16",
        "i16",
        "u32",
        "i32",
        "u64",
        "i64",
        "f32",
        "f64",
    }
    INLINE_ONLY_PREFIXES = (
        "flyology_simd__backends__native__",
        "native_",
        "compare_",
    )

    def __init__(self, architecture: str, temporary: Path) -> None:
        self.architecture = architecture
        self.temporary = temporary
        self.leaf_is_inlined = False
        self.vector_work_pattern = {
            "aarch64": (
                r"(^|[[:space:]])[a-z][a-z0-9]*"
                r"(\.(16b|8b|8h|4h|4s|2s|2d|1d)|[[:space:]]+v[0-9]+)"
            ),
            "x86_64": r"%xmm[0-9]",
        }.get(architecture, "")

    @staticmethod
    def _grep(
        pattern: str, file: Path, *options: str
    ) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            ["grep", *options, pattern, str(file)],
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            check=False,
        )

    def matches(self, pattern: str, file: Path) -> bool:
        return self._grep(pattern, file, "-Eiq").returncode == 0

    @staticmethod
    def _empty_regular_file(file: Path) -> bool:
        return file.is_file() and file.stat().st_size == 0

    def require_pattern(self, pattern: str, file: Path, description: str) -> None:
        if self._empty_regular_file(file):
            return
        if not self.matches(pattern, file):
            raise CodegenError(f"missing code-generation requirement: {description}")

    def forbid_pattern(self, pattern: str, file: Path, description: str) -> None:
        if self.matches(pattern, file):
            raise CodegenError(f"forbidden code generation found: {description}")

    @classmethod
    def register_operand_family(cls, lane_kind: str) -> bool:
        return lane_kind in cls.REGISTER_OPERAND_FAMILIES

    @classmethod
    def register_operand_leaf(cls, lane_kind: str, _operation: str = "") -> bool:
        return cls.register_operand_family(lane_kind)

    @classmethod
    def register_operand_memory_family(cls, lane_kind: str) -> bool:
        return cls.register_operand_family(lane_kind)

    def require_route_or_inlined(
        self, symbol: str, file: Path, description: str
    ) -> None:
        if self.matches(symbol, file) or file.name.endswith("-undefined.txt"):
            return
        self.require_pattern(
            self.vector_work_pattern,
            file,
            f"inlined work where {description}",
        )

    def require_route_branches_at_most(
        self, pattern: str, limit: int, file: Path, description: str
    ) -> None:
        previous = False
        actual = 0
        branch = re.compile(r"(call|jmp|bl|b)[ \t]")
        # The pattern itself remains POSIX ERE. Ask grep which individual lines
        # match it, then reproduce the oracle's one-line relocation look-ahead.
        matching_lines = set(self._grep(pattern, file, "-En").stdout.splitlines())
        matching_numbers = {
            int(line.split(":", 1)[0]) for line in matching_lines if ":" in line
        }
        for number, line in enumerate(file.read_text(errors="replace").splitlines(), 1):
            if previous and "__gnat_" not in line:
                actual += 1
            previous = False
            if branch.search(line) and number in matching_numbers:
                previous = True
        if previous:
            actual += 1
        if actual > limit:
            raise CodegenError(
                f"code-generation count mismatch: {description} ({actual} > {limit})"
            )

    def native_and_probes(self) -> Path:
        combined = self.temporary / "native-and-probes.txt"
        if not combined.is_file() or combined.stat().st_size == 0:
            sources = [self.temporary / "native.txt"]
            sources.extend(sorted(self.temporary.glob("*-probe.txt")))
            with combined.open("wb") as output:
                for source in sources:
                    try:
                        output.write(source.read_bytes())
                    except OSError:
                        # Matches the shell's ``cat ... 2>/dev/null || true``.
                        pass
        return combined

    @staticmethod
    def conversion_probe_symbol(source: str, target: str, operation: str) -> str:
        return (
            "integer_conversion_codegen_probe__"
            f"{source.split('x', 1)[0]}_{target.split('x', 1)[0]}_{operation}"
        )

    def count_matches(self, pattern: str, file: Path) -> int:
        lines = self._grep(pattern, file, "-Ei").stdout.splitlines()
        if self.architecture != "aarch64":
            return len(lines)
        seen: set[str] = set()
        count = 0
        for line in lines:
            fields = line.lstrip().split()
            address = fields[0].removesuffix(":") if fields else ""
            if re.fullmatch(r"[0-9a-fA-F]+", address):
                if address not in seen:
                    seen.add(address)
                    count += 1
            else:
                count += 1
        return count

    def require_at_most(
        self, pattern: str, limit: int, file: Path, description: str
    ) -> None:
        actual = self.count_matches(pattern, file)
        if actual > limit:
            raise CodegenError(
                f"code-generation count mismatch: {description} ({actual} > {limit})"
            )

    def require_native_route(
        self,
        pattern: str,
        limit: int,
        undefined_file: Path,
        _probe_file: Path,
        description: str,
    ) -> None:
        self.require_at_most(pattern, limit, undefined_file, description)

    def require_at_least(
        self, pattern: str, minimum: int, file: Path, description: str
    ) -> None:
        if self._empty_regular_file(file):
            return
        actual = self.count_matches(pattern, file)
        if actual < minimum:
            raise CodegenError(
                f"code-generation count mismatch: {description} ({actual} < {minimum})"
            )

    def require_count(
        self, pattern: str, expected: int, file: Path, description: str
    ) -> None:
        if self._empty_regular_file(file):
            return
        actual = self.count_matches(pattern, file)
        if actual != expected:
            raise CodegenError(
                f"code-generation count mismatch: {description} ({actual} != {expected})"
            )

    def extract_symbol(self, symbol: str, file: Path, output: Path) -> bool:
        wanted = symbol.lower()
        suffix = f"__{wanted}"
        found = False
        selected: list[str] = []
        label_pattern = re.compile(r"<([^>]+)>:")
        apple_label_pattern = re.compile(r"^_([A-Za-z0-9_$.]+):$")

        for line in file.read_text(errors="replace").splitlines(keepends=True):
            label = label_pattern.search(line)
            apple_label = apple_label_pattern.fullmatch(line.rstrip("\n"))
            name = ""
            if label:
                name = label.group(1)
            elif apple_label:
                name = apple_label.group(1)
            name = name.removeprefix("_").lower()
            exact = name == wanted
            shorthand = (
                not wanted.startswith("flyology_simd__")
                and len(name) > len(suffix)
                and name.endswith(suffix)
            )
            if not found and (exact or shorthand):
                found = True
                selected.append(line.rstrip("\r\n") + "\n")
                continue
            if found and name:
                break
            if found:
                selected.append(line.rstrip("\r\n") + "\n")

        if found:
            output.write_text("".join(selected))
            return True
        if symbol.startswith(self.INLINE_ONLY_PREFIXES):
            self.leaf_is_inlined = True
            output.write_text("")
            return True
        return False

    def extract_leaf_or_probe(
        self,
        leaf_symbol: str,
        native_file: Path,
        probe_symbol: str,
        probe_file: Path,
        output: Path,
    ) -> None:
        if self.extract_symbol(leaf_symbol, native_file, output):
            self.leaf_is_inlined = False
            return
        self.leaf_is_inlined = True
        if not self.extract_symbol(probe_symbol, probe_file, output):
            raise CodegenError(f"symbol not found: {probe_symbol}")
        remaining = sorted(
            set(
                re.findall(
                    r"flyology_simd__backends__native__[a-z_0-9]+",
                    output.read_text(errors="replace"),
                    re.IGNORECASE,
                )
            )
        )[:2]
        if len(remaining) == 1:
            if (
                self.extract_symbol(remaining[0], native_file, output)
                and output.stat().st_size
            ):
                self.leaf_is_inlined = False

    def require_leaf_instruction(
        self, pattern: str, expected: int, file: Path, description: str
    ) -> None:
        if self._empty_regular_file(file):
            return
        if expected == 0:
            self.require_count(pattern, 0, file, description)
        elif self.leaf_is_inlined:
            self.require_at_least(pattern, 1, file, description)
        else:
            self.require_count(pattern, expected, file, description)

    def require_vector_operand_transfers(
        self,
        leaf: Path,
        lane_kind: str,
        operation: str,
        arity: int,
    ) -> None:
        if self._empty_regular_file(leaf) or self.leaf_is_inlined:
            return
        if self.register_operand_leaf(lane_kind, operation):
            self.require_leaf_instruction(
                r"(^|[[:space:]])str[[:space:]]+q[0-9]+,[[:space:]]*\[",
                0,
                leaf,
                f"no result store in register-operand {lane_kind} {operation} leaf",
            )
            return
        self.require_leaf_instruction(
            r"(^|[[:space:]])ldr[[:space:]]+q0,[[:space:]]*\[",
            1,
            leaf,
            f"left operand transfer in {lane_kind} {operation} leaf",
        )
        self.require_leaf_instruction(
            r"(^|[[:space:]])ldr[[:space:]]+q1,[[:space:]]*\[",
            1 if arity == 2 else 0,
            leaf,
            (
                f"right operand transfer in {lane_kind} {operation} leaf"
                if arity == 2
                else f"no second memory operand in {lane_kind} {operation} leaf"
            ),
        )
        self.require_leaf_instruction(
            r"(^|[[:space:]])str[[:space:]]+q0,[[:space:]]*\[",
            1,
            leaf,
            f"result transfer in {lane_kind} {operation} leaf",
        )

    def require_sse_operand_transfers(
        self, leaf: Path, lane_kind: str, operation: str
    ) -> None:
        if self._empty_regular_file(leaf) or self.leaf_is_inlined:
            return
        if self.register_operand_leaf(lane_kind, operation):
            self.require_leaf_instruction(
                r"(^|[[:space:]])movdqu[[:space:]]+%xmm[0-9]+,"
                r"[[:space:]]*[^,]*\([^)]*\)",
                0,
                leaf,
                f"no result store in register-operand {lane_kind} {operation} leaf",
            )
            return
        self.require_leaf_instruction(
            r"(^|[[:space:]])movdqu[[:space:]]+[^,]*\([^)]*\)," r"[[:space:]]*%xmm0",
            1,
            leaf,
            f"left operand transfer in {lane_kind} {operation} leaf",
        )
        self.require_leaf_instruction(
            r"(^|[[:space:]])movdqu[[:space:]]+%xmm0," r"[[:space:]]*[^,]*\([^)]*\)",
            1,
            leaf,
            f"result transfer in {lane_kind} {operation} leaf",
        )

    def require_exact_neon_shaped(
        self,
        leaf: Path,
        instruction: str,
        shape: str,
        lane_kind: str,
        arity: int,
        description: str,
    ) -> None:
        if self._empty_regular_file(leaf):
            return
        register = r"v[0-9]+" if self.register_operand_family(lane_kind) else "v0"
        second = register if self.register_operand_family(lane_kind) else "v1"
        if arity == 2:
            operands = rf"{register},[[:space:]]*{register},[[:space:]]*{second}"
            shaped = (
                rf"{register}\.{shape},[[:space:]]*{register}\.{shape},"
                rf"[[:space:]]*{second}\.{shape}"
            )
        else:
            operands = rf"{register},[[:space:]]*{register}"
            shaped = rf"{register}\.{shape},[[:space:]]*{register}\.{shape}"
        pattern = (
            rf"(^|[[:space:]])({instruction}\.{shape}[[:space:]]+{operands}|"
            rf"{instruction}[[:space:]]+{shaped})"
        )
        self.require_leaf_instruction(pattern, 1, leaf, description)

    def require_exact_u8_operation(
        self,
        _caller_file: Path,
        selected_file: Path,
        instruction_pattern: str,
        _matching_symbols: str,
        description: str,
    ) -> None:
        self.require_pattern(
            instruction_pattern,
            selected_file,
            f"{description} exact selected operation",
        )

    def bind_u8_selected_operation(
        self,
        caller_file: Path,
        inline_pattern: str,
        matching_symbols: str,
        native_file: Path,
        selected_file: Path,
        description: str,
    ) -> None:
        native_relocation = {
            "aarch64": (r"ARM64_RELOC_BRANCH26.*flyology_simd__backends__native__"),
            "x86_64": (
                r"(X86_64_RELOC_BRANCH|R_X86_64_(PLT32|PC32))"
                r".*flyology_simd__backends__native__"
            ),
        }[self.architecture]
        if self.matches(inline_pattern, caller_file):
            self.require_count(
                native_relocation,
                0,
                caller_file,
                f"no selected Native function relocation in inline {description}",
            )
            shutil.copyfile(caller_file, selected_file)
            return
        self.require_count(
            rf"{native_relocation}({matching_symbols})"
            r"([+-]0x[[:xdigit:]]+)?([[:space:]]|$)",
            1,
            caller_file,
            f"one matching selected Native operation in {description}",
        )
        self.require_count(
            native_relocation,
            1,
            caller_file,
            f"only one selected Native function in {description}",
        )
        matches = self._grep(
            rf"flyology_simd__backends__native__({matching_symbols})",
            caller_file,
            "-Eio",
        ).stdout.splitlines()
        if not matches or not self.extract_symbol(
            matches[0], native_file, selected_file
        ):
            raise CodegenError(f"selected Native symbol not found in {description}")

    def require_final_avx_instruction(
        self, expected: str, file: Path, description: str
    ) -> None:
        matches = self._grep(
            r"(^|[[:space:]])v[a-z0-9]+", file, "-Eio"
        ).stdout.splitlines()
        actual = matches[-1].lstrip() if matches else ""
        if actual != expected:
            raise CodegenError(
                f"code-generation order mismatch: {description} "
                f"({actual} != {expected})"
            )

    @staticmethod
    def disassemble(source: Path) -> str:
        command = (
            ["otool", "-tvV", str(source)]
            if shutil.which("otool")
            else ["objdump", "-dr", str(source)]
        )
        return subprocess.run(
            command, check=True, text=True, stdout=subprocess.PIPE
        ).stdout
