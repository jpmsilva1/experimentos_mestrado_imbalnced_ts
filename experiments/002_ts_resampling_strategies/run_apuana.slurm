#!/bin/bash
#SBATCH --job-name=exp002
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --partition=long-simple
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --mem=128G
#SBATCH --time=7-00:00:00
#SBATCH --requeue

# 1. Ensure logs directory exists (run this before submitting via sbatch if submitting from outside)
mkdir -p logs
mkdir -p results/data

# 2. Activate environment
eval "$(micromamba shell hook --shell bash)"
# Check for a specific env or default to something sensible for the user to replace
if micromamba env list | grep -q "exp002"; then
    micromamba activate exp002
else
    micromamba activate base
    echo "Warning: exp002 env not found, using base."
fi

# 3. Export CPUs for R
export SLURM_CPUS_PER_TASK=$SLURM_CPUS_PER_TASK

echo "Starting sequential evaluation on dataset loop..."

# 4. Run the adapted R script
Rscript src/adapted/Exps.R

echo "Done."
