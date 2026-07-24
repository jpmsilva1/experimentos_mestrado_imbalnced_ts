#!/bin/zsh
set -e

# Activate Conda
source /Users/joaopms/miniconda3/etc/profile.d/conda.sh
conda activate paper_003_env

cd /Users/joaopms/Documents/Projeto_Mestrado/experiments/003_biased_resampling_spatiotemporal/src/original/inst

echo "=================================================="
echo "Starting Phase 1: Patching Spatio-Temporal Results"
echo "=================================================="
/Users/joaopms/miniconda3/envs/paper_003_env/bin/Rscript patch_external.R

echo "=================================================="
echo "Starting Phase 2: Internal Tuning Evaluation"
echo "=================================================="
/Users/joaopms/miniconda3/envs/paper_003_env/bin/Rscript exps_internalTuning.R

echo "=================================================="
echo "SUCCESS: ALL EXPERIMENTS COMPLETE!"
echo "=================================================="
