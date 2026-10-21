#!/usr/bin/env python3
"""Basic sanity checks; these are NOT a substitute for external validation."""
import argparse
import csv
import math
from pathlib import Path


def main():
    p=argparse.ArgumentParser()
    p.add_argument('csv_file', type=Path)
    p.add_argument('--max-relative-se', type=float, default=0.05)
    a=p.parse_args()
    with a.csv_file.open(newline='') as f:
        rows=list(csv.DictReader(f))
    warnings=[]
    for i, row in enumerate(rows, 1):
        for quantity in ('B_phi','B_energy','B_current'):
            try:
                b=float(row[quantity]); se=float(row['SE_'+quantity])
                if not math.isfinite(b) or b < 1-1e-9:
                    warnings.append(f'{i}: {quantity} invalid: {b}')
                if not math.isfinite(se) or se/b > a.max_relative_se:
                    warnings.append(f'{i}: {quantity} relative SE > {a.max_relative_se:.0%}: {se/b:.2%}')
            except (KeyError, ValueError, ZeroDivisionError) as ex:
                warnings.append(f'{i}: {quantity}: {ex}')
    print(f'{len(rows)} row(s), {len(warnings)} warning(s)')
    for msg in warnings[:30]: print('WARNING:', msg)
    if len(warnings)>30: print(f'... {len(warnings)-30} more warning(s)')
    if warnings: raise SystemExit(1)


if __name__ == '__main__':
    main()
