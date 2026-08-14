#!/usr/bin/env python3
"""Regression tests for the fail-closed SIMD completion inventory."""

from __future__ import annotations

import unittest

import check_simd_coverage as coverage


class CoverageInventoryTests(unittest.TestCase):
    def load(self) -> tuple[dict, list[dict]]:
        return coverage.load_inventory()

    def test_current_inventory_is_complete(self) -> None:
        data, families = self.load()
        state = coverage.validate(data, families)
        self.assertEqual(state["incomplete_overloads"], 0)

    def test_manifest_count_mismatch_is_rejected(self) -> None:
        data, families = self.load()
        data["probe"][0]["expected_rows"] += 1
        with self.assertRaisesRegex(ValueError, "manifest has 26 rows, expected 27"):
            coverage.validate(data, families)

    def test_unregistered_documentation_checker_is_rejected(self) -> None:
        data, families = self.load()
        families[0]["docs"]["checker"] = "missing-checker"
        with self.assertRaisesRegex(ValueError, "is not registered"):
            coverage.validate(data, families)

    def test_undeclared_gap_is_rejected(self) -> None:
        data, families = self.load()
        families[0]["semantic"] = {
            "status": "gap",
            "reason": "deliberate regression fixture",
            "closure": "restore complete evidence",
        }
        with self.assertRaisesRegex(ValueError, "completion contract requires a zero-gap"):
            coverage.validate(data, families)


if __name__ == "__main__":
    unittest.main()
