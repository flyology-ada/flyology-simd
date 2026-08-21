#!/usr/bin/env python3
"""Focused tests for the code-generation checker primitives."""

from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from codegen_checker import Checker, CodegenError


class CheckerTests(unittest.TestCase):
    def setUp(self) -> None:
        self.directory = tempfile.TemporaryDirectory()
        self.temporary = Path(self.directory.name)

    def tearDown(self) -> None:
        self.directory.cleanup()

    def evidence(self, name: str, text: str) -> Path:
        path = self.temporary / name
        path.write_text(text)
        return path

    def test_posix_patterns_and_diagnostics(self) -> None:
        evidence = self.evidence(
            "instructions.txt", "0000: add.16b v0, v1, v2\n0004: ret\n"
        )
        checker = Checker("x86_64", self.temporary)
        checker.require_pattern(r"add\.[[:xdigit:]]+b", evidence, "vector add")
        checker.forbid_pattern(r"scalar|portable", evidence, "portable code")
        with self.assertRaisesRegex(
            CodegenError, "missing code-generation requirement: xmm"
        ):
            checker.require_pattern(r"%xmm[0-9]+", evidence, "xmm")
        with self.assertRaisesRegex(
            CodegenError, "forbidden code generation found: uppercase"
        ):
            checker.forbid_pattern(r"ADD\.[[:xdigit:]]+B", evidence, "uppercase")

    def test_empty_inlined_body_bypasses_positive_checks(self) -> None:
        evidence = self.evidence("empty.txt", "")
        checker = Checker("aarch64", self.temporary)
        checker.require_pattern("missing", evidence, "empty leaf")
        checker.require_count("missing", 9, evidence, "empty leaf")
        checker.require_at_least("missing", 9, evidence, "empty leaf")

    def test_aarch64_count_deduplicates_relocation_addresses(self) -> None:
        evidence = self.evidence(
            "routes.txt",
            "  10: bl native_add\n  10: R_AARCH64_CALL26 native_add\n  14: bl native_add\nsymbolic native_add\n",
        )
        self.assertEqual(
            Checker("aarch64", self.temporary).count_matches("native_add", evidence), 3
        )
        self.assertEqual(
            Checker("x86_64", self.temporary).count_matches("native_add", evidence), 4
        )

    def test_route_count_ignores_runtime_relocations(self) -> None:
        evidence = self.evidence(
            "branches.txt",
            "  10: bl route\n  10: R_AARCH64_CALL26 __gnat_rcheck\n  14: bl route\n  14: R_AARCH64_CALL26 selected_route\n",
        )
        checker = Checker("aarch64", self.temporary)
        checker.require_route_branches_at_most(
            "route", 1, evidence, "one selected route"
        )
        with self.assertRaises(CodegenError):
            checker.require_route_branches_at_most(
                "route", 0, evidence, "no selected route"
            )

    def test_symbol_extraction_handles_gnu_apple_and_shorthand(self) -> None:
        source = self.evidence(
            "object.txt",
            "00000000 <package__wanted>:\n  0: body\n_apple_symbol:\n  4: apple\n00000008 <after>:\n  8: ret\n",
        )
        checker = Checker("aarch64", self.temporary)
        wanted = self.temporary / "wanted.txt"
        self.assertTrue(checker.extract_symbol("wanted", source, wanted))
        self.assertIn("body", wanted.read_text())
        apple = self.temporary / "apple.txt"
        self.assertTrue(checker.extract_symbol("apple_symbol", source, apple))
        self.assertIn("apple", apple.read_text())

    def test_missing_inline_leaf_is_empty_success(self) -> None:
        source = self.evidence("native.txt", "0000 <unrelated>:\n  0: ret\n")
        output = self.temporary / "inline.txt"
        checker = Checker("x86_64", self.temporary)
        self.assertTrue(
            checker.extract_symbol(
                "flyology_simd__backends__native__inlined", source, output
            )
        )
        self.assertTrue(checker.leaf_is_inlined)
        self.assertEqual(output.read_bytes(), b"")

    def test_final_avx_instruction(self) -> None:
        evidence = self.evidence(
            "avx.txt",
            "  vpshufb %ymm0,%ymm1,%ymm2\n  add %eax,%eax\n  vzeroupper\n  ret\n",
        )
        checker = Checker("x86_64", self.temporary)
        checker.require_final_avx_instruction("vzeroupper", evidence, "AVX order")
        with self.assertRaises(CodegenError):
            checker.require_final_avx_instruction("vpshufb", evidence, "AVX order")

    def test_native_and_probes_is_deterministic(self) -> None:
        self.evidence("native.txt", "native\n")
        self.evidence("z-probe.txt", "z\n")
        self.evidence("a-probe.txt", "a\n")
        combined = Checker("x86_64", self.temporary).native_and_probes()
        self.assertEqual(combined.read_text(), "native\na\nz\n")

    def test_conversion_probe_symbol(self) -> None:
        self.assertEqual(
            Checker.conversion_probe_symbol("u32x4", "f32x4", "convert_round"),
            "integer_conversion_codegen_probe__u32_f32_convert_round",
        )


if __name__ == "__main__":
    unittest.main()
