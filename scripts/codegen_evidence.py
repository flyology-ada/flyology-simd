#!/usr/bin/env python3
"""Build and collect disassembly evidence for the code-generation checker."""

from __future__ import annotations

import re
import shutil
import subprocess
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class Evidence:
    def __init__(
        self,
        architecture: str,
        avx2: str,
        wide_backend: str,
        temporary: Path,
    ) -> None:
        self.architecture = architecture
        self.avx2 = avx2
        self.wide_backend = wide_backend
        self.temporary = temporary
        # Keep object arguments relative to ROOT. Both otool and objdump print
        # the argument path in their output, so this is observable evidence.
        self.object_root = Path("obj") / architecture / avx2 / wide_backend
        self.probe_root = (
            Path("obj") / "codegen-probes" / architecture / avx2 / wide_backend
        )
        self.has_otool = shutil.which("otool") is not None

    def file(self, name: str) -> Path:
        return self.temporary / name

    def object(self, name: str) -> Path:
        return self.object_root / f"{name}.o"

    def probe(self, name: str) -> Path:
        return self.probe_root / f"{name}_codegen_probe.o"

    @staticmethod
    def run(command: list[str], output: Path | None = None) -> str:
        if output is None:
            subprocess.run(command, cwd=ROOT, check=True)
            return ""
        completed = subprocess.run(
            command,
            cwd=ROOT,
            check=True,
            text=True,
            stdout=subprocess.PIPE,
        )
        output.write_text(completed.stdout)
        return completed.stdout

    def build(self) -> None:
        externals = [
            f"-XFLYOLOGY_SIMD_ARCH={self.architecture}",
            f"-XFLYOLOGY_SIMD_AVX2={self.avx2}",
            f"-XFLYOLOGY_SIMD_WIDE_BACKEND={self.wide_backend}",
        ]
        self.run(["alr", "build", "--", *externals])
        self.run(
            [
                "alr",
                "exec",
                "--",
                "gprbuild",
                "-f",
                "-p",
                "-P",
                "scripts/codegen_probes.gpr",
                *externals,
            ]
        )

    def disassemble(
        self, source: Path, output: Path, *, show_all_symbols: bool = False
    ) -> None:
        if self.has_otool and not show_all_symbols:
            self.run(["otool", "-tvV", str(source)], output)
            return
        command = ["objdump", "-dr"]
        if self.has_otool and show_all_symbols:
            command.append("--show-all-symbols")
        completed = subprocess.run(
            [*command, str(source)],
            cwd=ROOT,
            check=True,
            text=True,
            stdout=subprocess.PIPE,
        )
        text = completed.stdout
        if self.has_otool and show_all_symbols:
            text = "".join(
                f"{line}\n"
                for line in text.splitlines()
                if not re.search(r"<ltmp[0-9]+>:$", line)
            )
        output.write_text(text)

    def nm(self, source: Path, output: Path, *, undefined: bool = True) -> None:
        command = ["nm"]
        if undefined:
            command.append("-u")
        self.run([*command, str(source)], output)

    def collect(self) -> None:
        native = self.object("flyology_simd-backends-native")
        algorithm = self.object("flyology_simd-algorithms-native")
        floating_algorithm = self.object("flyology_simd-algorithms-native_floating")
        self.disassemble(native, self.file("native.txt"))
        self.disassemble(algorithm, self.file("algorithm.txt"), show_all_symbols=True)
        self.nm(algorithm, self.file("algorithm-undefined.txt"))
        self.disassemble(
            floating_algorithm,
            self.file("floating-algorithm.txt"),
            show_all_symbols=True,
        )
        self.nm(floating_algorithm, self.file("floating-algorithm-undefined.txt"))
        self.disassemble(
            self.object("flyology_simd-features"), self.file("features.txt")
        )

        show_all = {
            "wide_reduction",
            "lane_arrangement",
            "bitwise",
            "integer_minmax",
            "saturating_arithmetic",
            "integer_conversion",
            "float_binary",
            "complete_memory",
            "comparison",
            "wrapping_arithmetic",
            "wide_construction",
            "wide_comparison",
            "wide_saturating_arithmetic",
            "wide_wrapping_arithmetic",
            "wide_bitwise",
            "wide_shift",
            "wide_minmax",
            "wide_mask",
            "wide_numeric_conversion",
            "wide_memory",
            "mask_core",
            "u8_value",
            "integer_reduction",
        }
        ordinary = {
            "slide",
            "permute",
            "wide",
            "wide_float_reduction",
            "wide_compact",
            "wide_movement",
            "float_reduction",
            "conversion64",
            "integer_shift",
            "unordered",
            "mask_position",
            "construction",
            "partial_memory",
            "bit_cast",
            "alignment",
            "table_lookup",
        }
        for name in sorted(show_all | ordinary):
            self.disassemble(
                self.probe(name),
                self.file(f"{name.replace('_', '-')}-probe.txt"),
                show_all_symbols=name in show_all,
            )

        optional = {
            "wide-byte": "flyology_simd-wide-byte_avx2_leaf",
            "wide-float": "flyology_simd-wide-float_avx2_leaf",
        }
        for output_name, object_name in optional.items():
            source = self.object(object_name)
            if (ROOT / source).is_file():
                self.disassemble(source, self.file(f"{output_name}.txt"))
                self.nm(source, self.file(f"{output_name}-undefined.txt"))
            else:
                self.file(f"{output_name}.txt").touch()
                self.file(f"{output_name}-undefined.txt").touch()

        extra = {
            "wide-lookup": "flyology_simd-wide-lookup_mechanism",
            "wide-permute": "flyology_simd-wide-permute_mechanism",
            "wide-float-reduction-leaf": (
                "flyology_simd-wide-float_reduce_selected_leaf"
            ),
        }
        for output_name, object_name in extra.items():
            self.disassemble(self.object(object_name), self.file(f"{output_name}.txt"))
        self.nm(
            self.object("flyology_simd-wide-lookup_mechanism"),
            self.file("wide-lookup-undefined.txt"),
        )
        self.run(
            ["objdump", "-r", str(self.object("flyology_simd-wide-lookup_mechanism"))],
            self.file("wide-lookup-relocs.txt"),
        )
        self.nm(
            self.object("flyology_simd-wide-compact_mechanism"),
            self.file("wide-compact-object-undefined.txt"),
        )
        self.nm(
            self.object("flyology_simd-wide-float_reduce_selected_leaf"),
            self.file("wide-float-reduction-leaf-undefined.txt"),
        )

        undefined = {
            "wide",
            "wide_reduction",
            "wide_float_reduction",
            "wide_compact",
            "wide_movement",
            "wide_numeric_conversion",
            "wide_memory",
            "slide",
            "float_reduction",
            "conversion64",
            "integer_shift",
            "unordered",
            "mask_position",
            "mask_core",
            "construction",
            "partial_memory",
            "bit_cast",
            "alignment",
            "table_lookup",
            "u8_value",
            "integer_reduction",
            "float_binary",
            "complete_memory",
            "comparison",
            "wide_saturating_arithmetic",
            "wide_wrapping_arithmetic",
            "wide_bitwise",
            "wide_shift",
            "wide_minmax",
            "wide_mask",
            "wrapping_arithmetic",
            "lane_arrangement",
            "bitwise",
            "integer_minmax",
            "saturating_arithmetic",
            "integer_conversion",
            "permute",
        }
        for name in sorted(undefined):
            self.nm(
                self.probe(name),
                self.file(f"{name.replace('_', '-')}-undefined.txt"),
            )
        self.nm(self.probe("slide"), self.file("slide-symbols.txt"), undefined=False)
        self.nm(
            self.probe("alignment"),
            self.file("alignment-symbols.txt"),
            undefined=False,
        )
        self.nm(native, self.file("native-undefined.txt"))
        self.nm(
            self.object("flyology_simd-wide-native"),
            self.file("wide-native-construction-undefined.txt"),
        )
        if self.architecture == "x86_64":
            excluded = {"flyology_simd-algorithms-avx2_implementation.o"}
            if self.wide_backend == "avx2":
                excluded.update(
                    {
                        "flyology_simd-wide-lookup_mechanism.o",
                        "flyology_simd-wide-byte_avx2_leaf.o",
                        "flyology_simd-wide-float_avx2_leaf.o",
                        "flyology_simd-wide-permute_mechanism.o",
                    }
                )
            baseline = self.file("baseline.txt")
            baseline.write_bytes(b"")
            for object_file in sorted((ROOT / self.object_root).glob("*.o")):
                if object_file.name in excluded:
                    continue
                part = self.file("baseline-part.txt")
                self.disassemble(object_file.relative_to(ROOT), part)
                with baseline.open("ab") as output:
                    output.write(part.read_bytes())
                part.unlink()
            if self.avx2 == "enabled":
                avx_object = self.object("flyology_simd-algorithms-avx2_implementation")
                self.disassemble(avx_object, self.file("avx2.txt"))
                self.nm(avx_object, self.file("avx2-undefined.txt"))
