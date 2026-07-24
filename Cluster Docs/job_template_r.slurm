#!/bin/bash
# ==============================================================================
# Apuana Cluster — Generic R Job Template
# Usage: Copy this file, fill in the CONFIGURATION block, then: sbatch job_r.slurm
# NOTE: R experiments are CPU-only. The --gpus flag is intentionally ABSENT.
# ==============================================================================

# ==============================================================================
# CONFIGURATION — Edit these values for your experiment
# ==============================================================================
# --mem: R socket clusters (doParallel) copy the full env per core.
#        128G is the safe minimum for large datasets. Increase if needed.
# --cpus-per-task: R will use this many threads via native C++ backends
#                  (e.g., ranger num.threads). Do NOT use doParallel socket
#                  clusters for large datasets — see APUANA_RUNBOOK.md §15.
# ==============================================================================

#SBATCH --job-name=my-r-experiment
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --partition=long-simple
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=128G
#SBATCH --time=7-00:00:00
#SBATCH --requeue
# NOTE: No --gpus flag. R experiments are CPU-only.

# ==============================================================================
# PRE-FLIGHT
# ==============================================================================
mkdir -p logs results/data

echo "=========================================="
echo "Job:      $SLURM_JOB_NAME"
echo "Job ID:   $SLURM_JOB_ID"
echo "Node:     $SLURMD_NODENAME"
echo "CPUs:     $SLURM_CPUS_PER_TASK"
echo "Started:  $(date)"
echo "=========================================="

set -e

# ==============================================================================
# THREAD BINDING
# Prevent R and its BLAS/OpenMP backends from spawning uncontrolled threads
# beyond the SLURM allocation. Without this, one job can thrash the entire node.
# ==============================================================================
export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK
export OPENBLAS_NUM_THREADS=$SLURM_CPUS_PER_TASK
export MKL_NUM_THREADS=$SLURM_CPUS_PER_TASK
export NUMEXPR_NUM_THREADS=$SLURM_CPUS_PER_TASK

echo "Thread binding: OMP/OPENBLAS/MKL set to $SLURM_CPUS_PER_TASK"

# ==============================================================================
# ENVIRONMENT — Activate micromamba R environment
# ==============================================================================
# Replace 'my_r_env' with your actual conda env name.
# Created by setup_r_env.sh
R_ENV_NAME="my_r_env"

eval "$(micromamba shell hook --shell bash)"

if ! micromamba env list | grep -q "$R_ENV_NAME"; then
    echo "ERROR: micromamba env '$R_ENV_NAME' not found."
    echo "Run setup_r_env.sh first."
    exit 1
fi

micromamba activate "$R_ENV_NAME"
echo "R: $(Rscript --version 2>&1)"

# ==============================================================================
# RUN
# ==============================================================================
# Replace 'main.R' with your actual script.
Rscript main.R

# ==============================================================================
# POST-RUN
# ==============================================================================
echo "=========================================="
echo "Job Finished: $(date)"
echo "=========================================="
