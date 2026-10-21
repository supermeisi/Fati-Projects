#!/usr/bin/env python3
"""Run 13 thickness configurations x 5 monoenergetic sources = 65 Geant4 jobs.

By default this reconstructs the ONE-FACTOR-AT-A-TIME subset in the
original report, NOT the 5**3 full factorial grid.
"""
import argparse
import csv
from pathlib import Path
import subprocess
import sys

ENERGIES = (0.5, 1.0, 1.5, 2.0, 2.5)
CONFIGS = (
    [(1, 1, water) for water in range(1, 6)]
    + [(1, iron, 1) for iron in range(2, 6)]
    + [(lead, 1, 1) for lead in range(2, 6)]
)
assert len(CONFIGS) == 13 and len(set(CONFIGS)) == 13


def parse_args():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--binary", type=Path, default=Path("build/gamma_buildup"))
    p.add_argument("--geometry", choices=("original", "equal-height"), default="original")
    p.add_argument("--height-cm", type=float, default=30.0)
    p.add_argument("--events", type=int, default=1000000)
    p.add_argument("--seed", type=int, default=424242)
    p.add_argument("--output-dir", type=Path, default=Path("results"))
    p.add_argument("--dry-run", action="store_true", help="Print commands without running Geant4")
    p.add_argument("--max-runs", type=int, default=65, help="Stop after N runs for testing")
    p.add_argument("--overwrite", action="store_true")
    return p.parse_args()


def main():
    args = parse_args()
    if args.events <= 0 or args.seed <= 0 or args.height_cm <= 0 or not 1 <= args.max_runs <= 65:
        raise SystemExit("events, seed, height must be positive; max-runs must be 1..65")
    binary = args.binary.expanduser().resolve()
    if not args.dry_run and not binary.is_file():
        raise SystemExit(f"Geant4 executable not found: {binary}. Build it first.")
    args.output_dir.mkdir(parents=True, exist_ok=True)
    rows = []
    for idx, (lead, iron, water, energy) in enumerate(
        ( (lead, iron, water, energy)
          for lead, iron, water in CONFIGS for energy in ENERGIES )
    ):
        if idx >= args.max_runs:
            break
        stem = f"Pb{lead}_Fe{iron}_H2O{water}_E{energy:g}".replace('.', 'p')
        outfile = args.output_dir / f"{stem}.csv"
        logfile = args.output_dir / f"{stem}.log"
        command = [str(binary), "--energy-mev", str(energy),
                   "--lead-cm", str(lead), "--iron-cm", str(iron),
                   "--water-cm", str(water), "--geometry", args.geometry,
                   "--height-cm", str(args.height_cm), "--events", str(args.events),
                   "--seed", str(args.seed + idx * 104729),
                   "--output", str(outfile.resolve())]
        print(f"[{idx + 1:02d}/65]", stem, flush=True)
        if args.dry_run:
            print(' '.join(command))
            continue
        if not outfile.exists() or args.overwrite:
            with logfile.open('w') as stream:
                proc = subprocess.run(command, stdout=stream, stderr=subprocess.STDOUT,
                                      check=False)
            if proc.returncode:
                raise SystemExit(f"Simulation failed ({proc.returncode}): {stem}; see {logfile}")
        with outfile.open(newline='') as stream:
            result = list(csv.DictReader(stream))
        if len(result) != 1:
            raise SystemExit(f"Expected 1 data row in {outfile}")
        rows.append(result[0])
        with (args.output_dir / "all_results.csv").open('w', newline='') as stream:
            writer = csv.DictWriter(stream, fieldnames=rows[0].keys())
            writer.writeheader()
            writer.writerows(rows)
    if not args.dry_run:
        print(f"Completed {len(rows)} results: {args.output_dir / 'all_results.csv'}")


if __name__ == "__main__":
    main()
