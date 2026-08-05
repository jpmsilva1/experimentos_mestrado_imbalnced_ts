#!/bin/bash
#SBATCH --job-name=exp010_model_sel
#SBATCH --output=logs/exp010_%j.out
#SBATCH --error=logs/exp010_%j.err
#SBATCH --cpus-per-task=48
#SBATCH --mem=256G
#SBATCH --time=2-00:00:00
#SBATCH --partition=long-simple

# Navigate to the adapted source directory (using SLURM submit dir)
cd $SLURM_SUBMIT_DIR/src/adapted

# Load the micromamba R environment
export PATH="$HOME/.local/bin:$PATH"
eval "$(micromamba shell hook --shell bash)"
micromamba activate exp010_env # Change this if your env has a different name

# Ensure results directory exists
mkdir -p results/tables
mkdir -p ../../logs

TOTAL=174
OUT_DIR="results/tables"

echo "=========================================================="
echo "Launching R script with 48 CPUs (Total datasets: $TOTAL)"
echo "=========================================================="

# Run R script in foreground
Rscript scripts/get-estimations.r
echo "get-estimations.r completed successfully!"
