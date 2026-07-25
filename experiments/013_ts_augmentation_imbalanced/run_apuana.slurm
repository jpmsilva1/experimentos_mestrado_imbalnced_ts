#!/bin/bash
#SBATCH --job-name=exp013_tser
#SBATCH --output=logs/exp013_%A_%a.out
#SBATCH --error=logs/exp013_%A_%a.err
#SBATCH --partition=long-simple
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=64G
#SBATCH --time=7-00:00:00
#SBATCH --array=0-8

set -e  # Halt immediately on any error

# Create logs directory if it doesn't exist
mkdir -p logs

# Activate the conda/mamba environment
eval "$(micromamba shell hook --shell bash)"
micromamba activate exp013_tser

# Set threading constraints for Python/NumPy/LightGBM based on SLURM CPUs
# This prevents thrashing the node when multiple array jobs run
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
export MKL_NUM_THREADS=$SLURM_CPUS_PER_TASK
export OPENBLAS_NUM_THREADS=$SLURM_CPUS_PER_TASK
export NUMEXPR_NUM_THREADS=$SLURM_CPUS_PER_TASK

# The list of datasets
DATASETS=(
    "nn5_daily_without_missing"
    "solar-energy"
    "traffic_nips"
    "electricity_nips"
    "taxi_30min"
    "rideshare_without_missing"
    "m4_hourly"
    "m4_weekly"
    "m4_daily"
)

# Get the dataset for this array task
DS=${DATASETS[$SLURM_ARRAY_TASK_ID]}

echo "========================================"
echo "Starting runs for dataset: $DS (Task ID: $SLURM_ARRAY_TASK_ID)"
echo "========================================"

# Navigate to the source directory
cd src/original

echo "Running run_models.py for $DS..."
python scripts/run/run_models.py "$DS"

echo "Running run_models_on_extra.py for $DS..."
python scripts/run/run_models_on_extra.py "$DS"

echo "Running run_variants.py for $DS..."
python scripts/run/run_variants.py "$DS"

echo "Running run_sensitivity.py for $DS..."
python scripts/run/run_sensitivity.py "$DS"

echo "Dataset $DS runs completed successfully!"
