#!/usr/bin/env python3
"""Make the three one-variable-at-a-time buildup plots for the paper."""
import argparse
import csv
from collections import defaultdict
from pathlib import Path


def main():
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt

    p = argparse.ArgumentParser()
    p.add_argument('--input', type=Path, default=Path('results/all_results.csv'))
    p.add_argument('--output-dir', type=Path, default=Path('results/figures'))
    p.add_argument('--quantity', choices=['B_phi','B_energy'], default='B_phi')
    a = p.parse_args()
    with a.input.open(newline='') as file:
        rows = list(csv.DictReader(file))
    if not rows:
        raise SystemExit('No rows found')
    a.output_dir.mkdir(parents=True, exist_ok=True)
    thickness_names = [('lead_cm','Lead'), ('iron_cm','Iron'), ('water_cm','Water')]
    for key, material in thickness_names:
        # Base 1,1,1 is shared by all three sweeps.
        subset = [r for r in rows if all(
            int(float(r[other])) == 1 for other, _ in thickness_names if other != key
        )]
        grouped = defaultdict(list)
        for row in subset:
            grouped[float(row['energy_MeV'])].append(
                (float(row[key]), float(row[a.quantity]),
                 float(row['SE_'+a.quantity])))
        plt.figure(figsize=(7,5))
        for energy, pts in sorted(grouped.items()):
            pts.sort()
            plt.errorbar([x for x, y, s in pts], [y for x, y, s in pts],
                         yerr=[s for x, y, s in pts], marker='o', capsize=2,
                         label=f'{energy:g} MeV')
        plt.xlabel(f'{material} radial thickness (cm)')
        plt.ylabel('Photon fluence buildup factor' if a.quantity=='B_phi'
                   else 'Energy fluence buildup factor')
        plt.title(f'Effect of {material.lower()} thickness')
        plt.grid(True, alpha=0.25)
        plt.legend()
        plt.tight_layout()
        out=a.output_dir/f'{a.quantity}_{material.lower()}.png'
        plt.savefig(out,dpi=200)
        plt.close()
        print('Saved', out)


if __name__ == '__main__':
    main()
