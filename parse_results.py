#!/usr/bin/env python3
"""
parse_results.py

Scans Vina log files (log_<ligand>.txt) in the current directory and
builds a markdown table of the best-scoring (mode 1) binding affinity
for each ligand, sorted strongest binder first.

Usage:
    python parse_results.py
"""

import re
import glob
import os

MODE_1_PATTERN = re.compile(r"^\s*1\s+(-?\d+\.\d+)")


def get_top_affinity(log_path):
    """Return the mode-1 (best-scoring) binding affinity from a Vina log."""
    with open(log_path) as f:
        for line in f:
            match = MODE_1_PATTERN.match(line)
            if match:
                return float(match.group(1))
    return None


def ligand_name_from_path(path):
    """log_benzene.txt -> benzene"""
    base = os.path.basename(path)
    if base.startswith("log_"):
        base = base[len("log_"):]
    if base.endswith(".txt"):
        base = base[: -len(".txt")]
    return base


def main():
    log_files = sorted(glob.glob("log_*.txt"))
    if not log_files:
        print("No log_*.txt files found in the current directory.")
        return

    rows = []
    for path in log_files:
        affinity = get_top_affinity(path)
        if affinity is None:
            print(f"Warning: could not parse affinity from {path}")
            continue
        rows.append((ligand_name_from_path(path), affinity))

    # Most negative affinity = strongest predicted binder
    rows.sort(key=lambda r: r[1])

    print("| Ligand | Affinity (kcal/mol) |")
    print("|--------|----------------------|")
    for ligand, affinity in rows:
        print(f"| {ligand.capitalize()} | {affinity:.3f} |")


if __name__ == "__main__":
    main()
