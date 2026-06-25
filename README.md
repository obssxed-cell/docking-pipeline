# Docking pipeline

A small, automated pipeline for screening multiple ligands against a
single protein receptor using AutoDock Vina. Built while learning
molecular docking from scratch. It chains together the steps that
are normally run one at a time by hand.

## What it does

```
raw input files  →  prepare & protonate  →  dock  →  analyze results
(receptor + ligands)   (Meeko, PDB2PQR,      (Vina      (PyMOL / table
                         pH 7.4)              scoring)    of affinities)
```

1. **Receptor prep** — protonates the receptor at a specified pH
   (PDB2PQR/PROPKA), then converts it to the `.pdbqt` format Vina
   requires (Meeko).
2. **Ligand prep** — converts each ligand from `.sdf` to `.pdbqt`
   (Meeko), looping over a list of ligands.
3. **Docking** — runs AutoDock Vina for each prepared ligand against
   the prepared receptor, using a defined grid box.
4. **Results** — `parse_results.py` reads Vina's log files and builds
   a ranked markdown table of best-scoring (mode 1) binding
   affinities.

## Setup

```bash
conda env create -f environment.yml
conda activate docking
```

## Usage

Place `receptor.pdb` and one `<ligand>.sdf` file per ligand in the
working directory, edit the `LIGANDS` array and grid box coordinates
in `dock.sh` to match your system, then:

```bash
./dock.sh
python parse_results.py
```

## Example output

Run against T4 lysozyme L99A (PDB 181L) as a validation system.
Benzene is the ligand resolved in the crystal structure, used here as
a sanity check that the pipeline reproduces a known pose before
trusting it on anything else:

| Ligand       | Affinity (kcal/mol) |
|--------------|----------------------|
| Toluene      | -6.252               |
| Phenol       | -5.653               |
| Benzene      | -5.456               |
| Hexylbenzene | -4.877               |
| Ethanol      | -2.674               |

Top-scoring benzene pose was confirmed against the crystal structure
in PyMOL before this pipeline was trusted for screening the other
ligands.

## Notes

- The grid box (`CENTER_X/Y/Z`, `SIZE_X/Y/Z`) is specific to the
  binding site you're targeting so I recommend you recompute it for your own receptor
  rather than reusing the example values I provided.
- The exact `pdb2pqr30` / `mk_prepare_receptor.py` flags in `dock.sh`
  may need small adjustments depending on your installed tool
  versions.
- `dock.sh` skips on a missing or failing
  ligand, so one bad input doesn't kill an entire screening run.

## Dependencies

- [AutoDock Vina](https://github.com/ccsb-scripps/AutoDock-Vina)
- [Meeko](https://github.com/forlilab/Meeko)
- [PDB2PQR](https://github.com/Electrostatics/pdb2pqr)
- [OpenBabel](https://github.com/openbabel/openbabel)
- [PyMOL](https://pymol.org/) (for pose visualization purposes only, not
  part of the automated script)
