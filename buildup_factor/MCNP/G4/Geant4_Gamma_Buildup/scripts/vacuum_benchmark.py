#!/usr/bin/env python3
"""Check vacuum cylinder against analytic uncollided lateral current/fluence."""
import argparse
import csv
import math
from pathlib import Path
import subprocess


def main():
    p=argparse.ArgumentParser()
    p.add_argument('--binary', type=Path, default=Path('build/gamma_buildup'))
    p.add_argument('--events', type=int, default=100000)
    p.add_argument('--output', type=Path, default=Path('vacuum_check.csv'))
    p.add_argument('--geometry', choices=['original','equal-height'], default='original')
    p.add_argument('--height-cm', type=float, default=30)
    a=p.parse_args()
    cmd=[str(a.binary.resolve()), '--vacuum-shield',
         '--lead-cm','1','--iron-cm','1','--water-cm','1',
         '--energy-mev','1', '--geometry',a.geometry,
         '--height-cm',str(a.height_cm), '--events',str(a.events),
         '--output',str(a.output.resolve())]
    subprocess.run(cmd, check=True)
    with a.output.open(newline='') as f:
        row=next(csv.DictReader(f))
    radius=3.0  # 1 cm Pb + 1 cm Fe + 1 cm H2O
    half_height=float(row['h_outer_cm'])/2
    mu_max=half_height/math.hypot(half_height,radius)
    expected_current=mu_max
    area=2*math.pi*radius*(2*half_height)
    expected_fluence=math.asin(mu_max)/area
    current=float(row['lateral_outgoing_gamma_count_per_primary'])
    phi=float(row['phi_total_per_cm2_per_primary'])
    b=float(row['B_phi'])
    print(f'Expected outgoing lateral photon count / primary = {expected_current:.8g}')
    print(f'Geant4 outgoing lateral photon count / primary   = {current:.8g}')
    print(f'Expected lateral photon fluence = {expected_fluence:.8g} photon/cm2/primary')
    print(f'Geant4 lateral photon fluence   = {phi:.8g} photon/cm2/primary')
    print(f'Vacuum buildup B_phi            = {b:.8g} (theory 1)')
    if abs(b-1)>1e-8:
        raise SystemExit('FAIL: vacuum buildup factor should be 1')
    # Current (binary photon exit) standard deviation <= 1/(2 sqrt(N)).
    if abs(current-expected_current)>5*0.5/math.sqrt(a.events):
        raise SystemExit('FAIL: lateral current does not match geometry')
    print('PASS: basic vacuum sanity checks. This does NOT validate the shielded physics.')


if __name__=='__main__':
    main()
