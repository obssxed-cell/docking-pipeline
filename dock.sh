#!/bin/bash
#
# dock.sh — automated docking pipeline
#
# Chains receptor preparation, protonation, ligand preparation, and
# AutoDock Vina docking for a list of ligands against one receptor.
#
# Usage:
#   ./dock.sh
#
# Expects in the working directory:
#   receptor.pdb        — the target protein structure
#   <ligand>.sdf         — one file per ligand listed in LIGANDS below
#
# Requires the conda environment with vina, pdb2pqr, openbabel, and
# meeko active (see environment.yml).

set -euo pipefail

# ---------------------------------------------------------------------
# Configuration — edit these for your system
# ---------------------------------------------------------------------
RECEPTOR="receptor"                                  # expects receptor.pdb
LIGANDS=("benzene" "toluene" "hexylbenzene" "phenol" "ethanol")
PH=7.4

# Docking grid box — these must match the binding site you're targeting.
# The values below are an example; recompute for your own receptor
# (e.g. centred on a known binding pocket).
CENTER_X=26.91
CENTER_Y=6.13
CENTER_Z=4.18
SIZE_X=20
SIZE_Y=20
SIZE_Z=20

# ---------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------
fail() { echo "ERROR: $1" >&2; exit 1; }

# ---------------------------------------------------------------------
# Step 0 — sanity checks (fail fast with a clear message rather than
# halfway through a 5-ligand run)
# ---------------------------------------------------------------------
[ -f "${RECEPTOR}.pdb" ] || fail "${RECEPTOR}.pdb not found in $(pwd)"
command -v vina               >/dev/null 2>&1 || fail "vina not found — is the docking conda env active?"
command -v pdb2pqr30          >/dev/null 2>&1 || fail "pdb2pqr30 not found — is the docking conda env active?"
command -v mk_prepare_ligand.py   >/dev/null 2>&1 || fail "Meeko (mk_prepare_ligand.py) not found"
command -v mk_prepare_receptor.py >/dev/null 2>&1 || fail "Meeko (mk_prepare_receptor.py) not found"

# ---------------------------------------------------------------------
# Step 1 — receptor preparation (protonate, then convert to pdbqt)
#
# NOTE: adjust the exact pdb2pqr30 / mk_prepare_receptor.py flags below
# to match whatever invocation you've already validated for your
# receptor — CLI options vary slightly by tool version.
# ---------------------------------------------------------------------
echo "==> Preparing receptor: ${RECEPTOR}.pdb (pH ${PH})"
pdb2pqr30 --ph-calc-method propka --with-ph "${PH}" \
    --pdb-output "${RECEPTOR}_h.pdb" \
    "${RECEPTOR}.pdb" "${RECEPTOR}.pqr" \
    || fail "Receptor protonation failed"

mk_prepare_receptor.py -i "${RECEPTOR}_h.pdb" -o "${RECEPTOR}.pdbqt" \
    || fail "Receptor pdbqt conversion failed"

# ---------------------------------------------------------------------
# Step 2 — loop over ligands: prepare + dock each one
# ---------------------------------------------------------------------
for LIGAND in "${LIGANDS[@]}"; do
    echo "----------------------------------------"
    echo "==> Docking: ${LIGAND}"

    if [ ! -f "${LIGAND}.sdf" ]; then
        echo "    skipping — ${LIGAND}.sdf not found"
        continue
    fi

    if ! mk_prepare_ligand.py -i "${LIGAND}.sdf" -o "${LIGAND}.pdbqt"; then
        echo "    skipping — ligand preparation failed for ${LIGAND}"
        continue
    fi

    if ! vina --receptor "${RECEPTOR}.pdbqt" --ligand "${LIGAND}.pdbqt" \
              --center_x "${CENTER_X}" --center_y "${CENTER_Y}" --center_z "${CENTER_Z}" \
              --size_x   "${SIZE_X}"   --size_y   "${SIZE_Y}"   --size_z   "${SIZE_Z}" \
              --out "${LIGAND}_out.pdbqt" --log "log_${LIGAND}.txt"; then
        echo "    docking failed for ${LIGAND}"
        continue
    fi

    echo "    done — see log_${LIGAND}.txt"
done

echo "----------------------------------------"
echo "Pipeline complete. Run parse_results.py to build a results table."
