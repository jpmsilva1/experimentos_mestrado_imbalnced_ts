#!/bin/bash
#SBATCH --job-name=paper003-st-resampling
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --partition=long-simple
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --mem=120G
#SBATCH --time=7-00:00:00

# Create logs directory if it doesn't exist
mkdir -p logs

# Activate the R environment (per Apuana runbook instructions)
eval "$(micromamba shell hook --shell bash)"
micromamba activate paper_003_env

echo "=== Installing Local Patched Packages ==="
R CMD INSTALL scratch/uba
R CMD INSTALL src/original

echo "=== Running Phase 1: Patch External (Spatio-Temporal configs) ==="
cd src/original/inst
Rscript patch_external.R

echo "=== Running Phase 2: Internal Tuning ==="
Rscript exps_internalTuning.R

echo "=== Done ==="
