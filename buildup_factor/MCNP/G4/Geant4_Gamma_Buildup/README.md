# Geant4: gamma-ray buildup factors in Pb / Fe / H2O cylinders

This project rebuilds the shielding calculation from scratch in **Geant4 11.x**.
It generates a monoenergetic isotropic gamma point source at (0,0,0), transports
photons and their secondaries through three coaxial cylinders, and tallies the
**outgoing lateral-surface photon fluence** and **energy fluence**, separately
for all photons and uncollided primary photons.

It is NOT a translation that preserves potentially incorrect MCNP materials,
energy bins, or tally normalization. Results must be independently validated
before being cited in a journal article.

## Prerequisites

- Working **Geant4 11.x** installation with G4EMLOW / Livermore datasets;
  `geant4-config --version` should work after sourcing its setup script.
- C++17 compiler, CMake >= 3.16, Python 3.9+.
- `matplotlib` only if you want figures: `python3 -m pip install matplotlib`.
- ROOT, MCNP, MATLAB and proprietary software are **not** needed.

## Build (Linux)

```bash
# If Geant4 is installed in ~/geant4-install (adjust to your install):
source ~/geant4-install/bin/geant4.sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j 4
```

If CMake cannot find Geant4, provide its installed CMake package directory:

```bash
cmake -S . -B build -DGeant4_DIR=/path/to/lib/cmake/Geant4
```

## First smoke test

```bash
./build/gamma_buildup --geometry original --energy-mev 2 \
  --lead-cm 1 --iron-cm 1 --water-cm 1 --events 10000 \
  --seed 1234 --output sample.csv
python3 scripts/check_results.py sample.csv
```

A 10,000-event test checks that the software runs, **not** the accuracy of
buildup factor. `check_results.py` may report that statistical uncertainty is
too high; this is expected for small tests and is not necessarily a code bug.

## Full 65-case sweep

13 thickness combinations (cm), using **one-factor-at-a-time**, not 625:

- Pb=1, Fe=1, H2O=1..5: five combinations;
- Pb=1, Fe=2..5, H2O=1: four more;
- Pb=2..5, Fe=1, H2O=1: four more.

For each combination: gamma energy = 0.5, 1.0, 1.5, 2.0, 2.5 MeV.

```bash
python3 scripts/run_scan.py --dry-run
python3 scripts/run_scan.py --events 10000 --max-runs 1
python3 scripts/run_scan.py --events 1000000 --overwrite
python3 scripts/check_results.py results/all_results.csv
python3 scripts/plot_results.py --quantity B_phi
python3 scripts/plot_results.py --quantity B_energy
```

`results/all_results.csv` has 65 rows after the complete sweep; per-case
CSV files and run logs are also saved. Every case gets an independent seed.
Do not mix results with different event counts or geometry variants in one
publication table. To avoid mixing, set a separate `--output-dir` for each.

Example for the same nominal height for all cylinders:

```bash
python3 scripts/run_scan.py --geometry equal-height --height-cm 30 \
  --events 1000000 --output-dir results_equal_height
```

## Critical geometric ambiguity in the original project

**The old `shielding.i` and the 11-page project report disagree.** The posted
MCNP file uses the following concentric *solid* cylinders:

| Radius (cm) | Total height (cm) | Material |
| ---: | ---: | --- |
| 5 | 10 | Pb core |
| 10 | 20 | Fe outside Pb |
| 15 | 30 | H2O outside Fe |

It does **not** contain three cylinders of equal height, although the report
says they have equal height.

This code has two explicit options:

1. `--geometry original` (default): reproduce the old rule **half-height =
   cumulative outer radius**. For (Pb,Fe,H2O)=(5,5,5), radii are 5,10,15 cm,
   full heights 10,20,30 cm. For each of the 13 thickness combinations, this
   option assumes the radial dimensions and respective axial half-heights vary
   together. Without the original MATLAB parameter generation, it **cannot**
   be proven this exactly reproduces the 65 old input files.
2. `--geometry equal-height --height-cm 30`: fix total height of all three
   coaxial cylinders at 30 cm; radial layer thicknesses vary independently.
   This matches the *written* equal-height assumption, but is not the same
   geometry as the posted MCNP file.

Choose ONE geometry for the new paper and clearly document it. These options
cannot be pooled or directly compared without noting the geometry change.

## Physics and scoring

- **Material:** Geant4 NIST `G4_Pb`, `G4_Fe`, `G4_WATER` (correct H2O), and
  `G4_Galactic` outside the shield.
- **Source:** one primary gamma per event, at the common cylinder center,
  isotropic in 4-pi steradians; no source cavity.
- **Physics:** `G4EmLivermorePhysics` (Compton, photoelectric, Rayleigh,
  pair production and associated secondary electron/positron physics),
  `G4DecayPhysics`, and 0.01 mm default range production cut.
- **Scoring surface:** **outer curved lateral surface** only; the two endcaps
  are *excluded*. Only outward crossings from water to vacuum are counted.
- **Uncollided:** primary gamma (parent ID 0) that has undergone **no physics
  interaction**, rather than a photon selected by an energy window. All
  scattered primaries and secondary photons contribute to total fluence.
- **Surface fluence estimator:** each exiting photon contributes
  `w / (A |u . n|)` in photons/cm2 per source event, where `u` is momentum
  direction, `n` is outward surface normal, `A=2*pi*R*H` is lateral surface
  area, and `w` is track statistical weight. Grazing photons are strongly
  weighted; examine statistical uncertainty carefully.
- **Energy fluence estimator:** same surface fluence contribution times gamma
  kinetic energy in MeV, analogous in intent to an energy-weighted F2 tally.
- **Photon current:** total weighted number of outward photon crossings per
  source event, also provided for diagnostic comparison. This is **not**
  surface fluence and must not be mislabeled as such.
- **Buildup:** `B_phi = Phi_total / Phi_uncollided` and
  `B_energy = Psi_total / Psi_uncollided`. These are **fluence** and
  **energy-fluence** buildup factors, not absorbed-dose buildup factors.
- **Uncertainty:** first-order delta-method standard error for the ratio,
  computed from **per-event** sums and their covariance (not independent
  numerator/denominator errors); saved as `SE_B_phi` and `SE_B_energy`.

### Relation to MCNP output

Your GitHub input uses `*F2:P 3.1`, which scores an **energy-weighted** surface
fluence. In Geant4, compare **B_energy** if your published quantity was really
energy-fluence buildup. Standard photon-fluence buildup is **B_phi**. The
MCNP input also has energy bins near 0.200 MeV even when gamma energy is
2.000 MeV, and the former H/O atomic fractions were reversed. You cannot
legitimately claim either old and new numbers are identical or simply apply a
correction coefficient to old 65 values. Rerun the selected Geant4 model.

### Limitations and validation needed for publication

- The lateral **outward-only** fluence definition may differ from all-sided
  MCNP F2 conventions or other papers; explicitly state the scored surface,
  angular weighting and which population is being tallied.
- No electromagnetic transport code comparison is self-validating. First
  check vacuum/no-shield transmission or an analytic uncollided attenuation
  benchmark, then a published single-material benchmark with **matching**
  geometry and tally definition. Compare both relative errors and Geant4
  uncertainty intervals.
- At high attenuation, the uncollided fluence can be small, causing large
  ratios and unstable uncertainties. Increase histories as needed and inspect
  convergence (1e5 vs 1e6 vs more, independent seeds).
- The physics models, cross-section datasets, cuts, Geant4 version and
  geometry must be recorded in your methods section. Do a convergence check
  for the default production cut, especially for low-energy secondary photons.
- The current script preserves *only 13* thickness combinations; it is not a
  full 5x5x5 factorial study. Avoid claims about layer-order effects unless
  you additionally simulate alternative orders.
- This source is **not yet compiled or run against Geant4 in the author's
  environment**; run a smoke test and examine any compiler warnings and
  tracking/geometry logs before relying on the results.

## References

- [Geant4 installation and CMake integration](https://geant4.web.cern.ch/documentation/dev/ig_html/InstallationGuide/buildtools.html)
- [Geant4 Livermore EM physics](https://geant4.web.cern.ch/documentation/dev/plg_html/PhysicsListGuide/electromagnetic/Liv.html)
- [Geant4 step/boundary API](https://geant4.web.cern.ch/documentation/pipelines/master/faq_html/FAQ/tracksAndSteps.html)
- [Geant4 surface flux scoring conventions](https://geant4.web.cern.ch/documentation/dev/bfad_html/ForApplicationDevelopers/Detector/hit.html)

## Analytic vacuum benchmark (run before the 65 shielded cases)

The executable also accepts `--vacuum-shield` and replaces all shielding
materials with vacuum while retaining the same nested geometric boundaries.
Then the exact buildup factors are **1**, because no collisions occur.
For a point source at the center, outer-cylinder radius `R`, and outer
half-height `h`, the expected probability of first leaving through the curved
side instead of a cap is

`P_side = h / sqrt(R^2 + h^2)`.

The surface-fluence estimator has expectation

`Phi_lateral = asin(P_side) / (2*pi*R*(2*h))`,

where radius and half-height are in cm, giving photon/cm2/source.

```bash
python3 scripts/vacuum_benchmark.py --events 100000
```

This checks isotropy, geometry, scoring and uncollided classification. It does
**not** replace validation of cross sections and buildup factors in shielding
materials. Use a published reference benchmark with matching definitions.
