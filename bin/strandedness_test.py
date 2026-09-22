#!/usr/bin/env python3
"""Unit tests for the strandedness parser."""

import csv
import importlib.util
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).parents[1] / "bin" / "strandedness.py"
SPEC = importlib.util.spec_from_file_location("strandedness", SCRIPT)
strandedness = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(strandedness)


class ParseTests(unittest.TestCase):
    """Tests for parsing RSeQC infer_experiment reports."""

    def write_report(self, content: str) -> str:
        """Write a temporary report and return its path."""
        report = tempfile.NamedTemporaryFile(mode="w", delete=False)
        report.write(content)
        report.close()
        self.addCleanup(Path(report.name).unlink, missing_ok=True)
        return report.name

    def test_single_end_forward_stranded_report(self) -> None:
        filepath = self.write_report('"++,--": 0.85\n"+-,-+": 0.10\n')

        result = strandedness.parse(filepath)

        self.assertEqual(
            result,
            {
                "sequencing": "single",
                "strandedness": "fr-secondstrand",
                "alias": "forward",
            },
        )

    def test_paired_end_forward_stranded_report(self) -> None:
        filepath = self.write_report(
            'This is paired-end data\n'
            '"1++,1--,2+-,2-+": 0.90\n'
            '"1+-,1-+,2++,2--": 0.10\n'
        )

        result = strandedness.parse(filepath)

        self.assertEqual(result["sequencing"], "paired")
        self.assertEqual(result["strandedness"], "fr-secondstrand")
        self.assertEqual(result["alias"], "forward")

    def test_reverse_stranded_report(self) -> None:
        filepath = self.write_report('"++,--": 0.10\n"+-,-+": 0.85\n')

        result = strandedness.parse(filepath)

        self.assertEqual(result["strandedness"], "fr-firststrand")
        self.assertEqual(result["alias"], "reverse")

    def test_below_threshold_report_is_unstranded(self) -> None:
        filepath = self.write_report('"++,--": 0.70\n"+-,-+": 0.20\n')

        result = strandedness.parse(filepath)

        self.assertEqual(result["strandedness"], "fr-unstranded")
        self.assertEqual(result["alias"], "")

    def test_report_without_recognized_pattern_raises_value_error(self) -> None:
        filepath = self.write_report("No strandedness pattern\n")

        with self.assertRaises(ValueError):
            strandedness.parse(filepath)

    def test_missing_report_raises_runtime_error(self) -> None:
        with self.assertRaises(RuntimeError):
            strandedness.parse("missing-report.txt")


class CommandLineTests(unittest.TestCase):
    """Tests for the script's CSV-writing command-line interface."""

    def test_command_line_writes_csv(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            directory_path = Path(directory)
            report = directory_path / "report.txt"
            report.write_text('"++,--": 0.85\n', encoding="utf-8")

            subprocess.run(
                [sys.executable, str(SCRIPT), str(report), "experiment", "condition"],
                cwd=directory,
                check=True,
            )

            with (directory_path / "infer.csv").open(newline="", encoding="utf-8") as output:
                rows = list(csv.reader(output))

        self.assertEqual(rows[0], ["experiment", "condition", "sequencing", "strandedness", "alias"])
        self.assertEqual(rows[1], ["experiment", "condition", "single", "fr-secondstrand", "forward"])


if __name__ == "__main__":
    unittest.main()
