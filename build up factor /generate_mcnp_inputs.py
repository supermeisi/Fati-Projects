"""Port of Buildupfactor.m: generate MCNPX input decks (not MCNPX runs).

WARNING: Legacy surface entries appear malformed, and the original energy
loop always uses erg=2. Preserved verbatim for reproducibility, not validity.
"""
import argparse
from itertools import product
from pathlib import Path

THICKNESSES = (1, 2, 3, 4, 5)
ENERGIES = (0.2, 0.5, 1, 1.5, 2)

def generate(output: Path, use_filename_energy: bool = False):
    output.mkdir(parents=True, exist_ok=True)
    run_commands = []
    for energy, lead, iron, water in product(ENERGIES, THICKNESSES, THICKNESSES, THICKNESSES):
        name = f'BuildUp_{energy:g}_{lead}_{iron}_{water}'
        source_energy = energy if use_filename_energy else 2
        deck = f''' ************ Buildup ********************
c ccccccccccccccc Cell card ccccccccccccccc
1 1 -11.35  -1     imp:p=1
2 2 -7.874  1 -2   imp:p=1
3 3 -1      2 -3   imp:p=1
4 0 -4 #1 #2 #3    imp:p=1
5 0  4             imp:p=0

c ************ Surface Card *****************
c *******************************************
1 rcc 0 0 -5 0 0 10 5 {lead}
2 rcc 0 0 -10 0 0 20 10{lead + iron}
3 rcc 0 0 -15 0 0 30 15{lead + iron + water}
4 so 50

c ************ Data Card ********************
c *******************************************
mode p
m1 82000 1
m2 26000 1
m3 1001 0.3333 8016 0.6667
sdef erg={source_energy:g} pos=-10 0 0
f2:p 3.1
nps 1e6
'''
        (output / f'{name}.i').write_text(deck, encoding='utf-8')
        run_commands.append(f'mcnpx2.7 i={name}.i o={name}_outa.o')
    (output / 'RunAllOfMyProgram.sh').write_text('#!/usr/bin/env bash\nset -euo pipefail\ncd "$(dirname "$0")"\n'+'\n'.join(run_commands)+'\n', encoding='utf-8')
    print(f'Generated {len(run_commands)} MCNPX input files in {output}')
    print('WARNING: Original RCC surface cards are likely invalid; validate and correct geometry before transport.')
    print('WARNING: These are input decks only. MCNPX is not included or required for generation.')
    if not use_filename_energy: print('WARNING: Preserved original fixed source energy (2 MeV) for all filenames.')

def main():
    p = argparse.ArgumentParser()
    p.add_argument('--output', type=Path, default=Path('results/mcnp_inputs'))
    p.add_argument('--use-filename-energy', action='store_true', help='Use each filename energy for SDEF instead of legacy fixed 2 MeV')
    a = p.parse_args()
    generate(a.output, a.use_filename_energy)

if __name__ == '__main__':
    main()
