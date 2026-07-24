#!/bin/bash
# ==============================================================================
# Apuana Cluster — Generic Python Job Template
# Usage: Copy this file, fill in the CONFIGURATION block, then: sbatch job.slurm
# Confirmed flags from: job_apuana.slurm (production reference)
# ==============================================================================

# ==============================================================================
# CONFIGURATION — Edit these values for your experiment
# ==============================================================================
# --job-name    : Short name shown in squeue. Use kebab-case.
# --partition   : See partition guide in APUANA_RUNBOOK.md
#                 debug (30min) | short-simple (2d) | long-simple (7d)
# --cpus-per-task: How many CPU cores to request. Match to your parallelism.
# --mem         : Total RAM for the job (e.g., 32G, 64G, 128G).
# --time        : Wall-clock limit. Format: D-HH:MM:SS or HH:MM:SS.
#                 Always set lower than the partition maximum.
# --gpus        : Number of GPUs. Apuana uses --gpus=N (not --gres=gpu:N).
#                 Omit this line entirely for CPU-only jobs.
# ==============================================================================

#SBATCH --job-name=my-experiment
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --partition=long-simple
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --gpus=1
#SBATCH --mem=64G
#SBATCH --time=7-00:00:00
#SBATCH --requeue

# ==============================================================================
# PRE-FLIGHT
# ==============================================================================
mkdir -p logs results/data

echo "=========================================="
echo "Job:      $SLURM_JOB_NAME"
echo "Job ID:   $SLURM_JOB_ID"
echo "Node:     $SLURMD_NODENAME"
echo "CPUs:     $SLURM_CPUS_PER_TASK"
echo "GPU:      $CUDA_VISIBLE_DEVICES"
echo "Started:  $(date)"
echo "=========================================="

# Fail fast: exit immediately if any command fails
set -e

# ==============================================================================
# ENVIRONMENT — Activate the per-project virtualenv
# ==============================================================================
# Replace 'my_project_env' with your actual virtualenv name.
# Created by setup_env.sh
VENV_PATH="$HOME/envs/my_project_env"

if [ ! -d "$VENV_PATH" ]; then
    echo "ERROR: virtualenv not found at $VENV_PATH"
    echo "Run setup_env.sh first."
    exit 1
fi

source "$VENV_PATH/bin/activate"
echo "Python: $(which python) — $(python --version)"

# ==============================================================================
# RUN
# ==============================================================================
# Replace 'run_experiment.py' with your actual script.
python run_experiment.py

# ==============================================================================
# POST-RUN
# ==============================================================================
echo "=========================================="
echo "Job Finished: $(date)"
echo "=========================================="
