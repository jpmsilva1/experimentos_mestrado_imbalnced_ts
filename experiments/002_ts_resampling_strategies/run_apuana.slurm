#!/bin/bash
#SBATCH --job-name=exp002_ts_resampling
#SBATCH --output=logs/exp002_%j.out
#SBATCH --error=logs/exp002_%j.err
#SBATCH --partition=long-simple
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=48
#SBATCH --mem=64G
#SBATCH --time=7-00:00:00
#SBATCH --requeue

# Navigate to experiment root (safe regardless of where sbatch was called from)
cd $SLURM_SUBMIT_DIR

# Ensure output directories exist
mkdir -p logs
mkdir -p src/adapted/results/data

# Activate micromamba R environment
export PATH="$HOME/.local/bin:$PATH"
eval "$(micromamba shell hook --shell bash)"
micromamba activate exp002_env  # Change if your env has a different name

TOTAL=24

echo "=========================================================="
echo "Exp002: TS Resampling Strategies (Sequential, $TOTAL datasets)"
echo "Submission dir: $SLURM_SUBMIT_DIR"
echo "CPUs allocated: $SLURM_CPUS_PER_TASK"
echo "=========================================================="

# Run the adapted R script
Rscript src/adapted/Exps.R

echo "=========================================================="
echo "Exp002 R script finished. Checking completeness..."
COMPLETED=$(ls src/adapted/results/data/results_dataset_*.Rdata 2>/dev/null | wc -l)
echo "Datasets completed: $COMPLETED / $TOTAL"
if [ "$COMPLETED" -eq "$TOTAL" ]; then
    echo "All $TOTAL datasets done. Run merge_results.R to consolidate."
else
    echo "WARNING: Only $COMPLETED/$TOTAL datasets completed. Resubmit to resume from checkpoint."
fi
echo "=========================================================="
