#!/bin/bash
#SBATCH --job-name=exp013_dist
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --partition=long-simple
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=120G
#SBATCH --time=7-00:00:00

set -e  # Halt immediately on any error

# Create logs directory if it doesn't exist
mkdir -p logs

# Activate the conda/mamba environment
eval "$(micromamba shell hook --shell bash)"
micromamba activate exp013_tser

# VERY IMPORTANT: Since we are running multiple python processes concurrently,
# we MUST force numpy/lightgbm to be strictly single-threaded to avoid CPU thrashing.
export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1

# The list of ALL datasets. The python scripts will instantly skip any
# series that already have a .csv lock file in the results folder, picking up exactly
# where they left off!
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

cd src/original

for DS in "${DATASETS[@]}"; do
    echo "========================================"
    echo "Starting runs for dataset: $DS"
    echo "========================================"

    # We use xargs to spawn N parallel instances of the same script (N = SLURM_CPUS_PER_TASK).
    # The python scripts' internal CSV locks naturally handle the dynamic task distribution!
    
    echo "Running run_models.py for $DS..."
    seq 1 $SLURM_CPUS_PER_TASK | xargs -n 1 -P $SLURM_CPUS_PER_TASK -I {} python scripts/run/run_models.py "$DS" > /dev/null 2>&1

    echo "Running run_models_on_extra.py for $DS..."
    seq 1 $SLURM_CPUS_PER_TASK | xargs -n 1 -P $SLURM_CPUS_PER_TASK -I {} python scripts/run/run_models_on_extra.py "$DS" > /dev/null 2>&1

    echo "Running run_variants.py for $DS..."
    seq 1 $SLURM_CPUS_PER_TASK | xargs -n 1 -P $SLURM_CPUS_PER_TASK -I {} python scripts/run/run_variants.py "$DS" > /dev/null 2>&1

    echo "Running run_sensitivity.py for $DS..."
    seq 1 $SLURM_CPUS_PER_TASK | xargs -n 1 -P $SLURM_CPUS_PER_TASK -I {} python scripts/run/run_sensitivity.py "$DS" > /dev/null 2>&1

    echo "Dataset $DS runs completed successfully!"
done
