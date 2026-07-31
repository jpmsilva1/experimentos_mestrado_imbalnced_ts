#!/bin/bash
#SBATCH --job-name=exp013_dist
#SBATCH --output=logs/%x_%j.out
#SBATCH --error=logs/%x_%j.err
#SBATCH --partition=long-simple
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --mem=120G
#SBATCH --time=7-00:00:00

# Intentionally NOT using set -e: individual series failures should not abort the entire multi-day job
set -u

mkdir -p logs

eval "$(micromamba shell hook --shell bash)"
micromamba activate exp013_tser

export OMP_NUM_THREADS=1
export MKL_NUM_THREADS=1
export OPENBLAS_NUM_THREADS=1
export NUMEXPR_NUM_THREADS=1

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

# Background Monitor Function
run_with_progress() {
    local SCRIPT_NAME=$1
    local OUT_DIR=$2
    local TOTAL=$3

    echo "=========================================================="
    echo "Launching 8 workers for $SCRIPT_NAME (Dataset: $DS | Total: $TOTAL)"
    echo "=========================================================="
    
    # Launch 8 workers in the background
    seq 1 $SLURM_CPUS_PER_TASK | xargs -n 1 -P $SLURM_CPUS_PER_TASK -I {} python "scripts/run/$SCRIPT_NAME" "$DS" > /dev/null &
    WORKER_PID=$!
    
    # Monitor loop: Print progress every 60 seconds
    while kill -0 $WORKER_PID 2>/dev/null; do
        if [ -d "$OUT_DIR" ]; then
            COUNT=$(ls "$OUT_DIR" | grep "^${DS}_" | wc -l | tr -d ' ')
            if [ "$TOTAL" -gt 0 ]; then
                PERCENT=$(( COUNT * 100 / TOTAL ))
                echo "$(date '+%Y-%m-%d %H:%M:%S') | $DS | $SCRIPT_NAME | [${PERCENT}%] $COUNT / $TOTAL completed"
            else
                echo "$(date '+%Y-%m-%d %H:%M:%S') | $DS | $SCRIPT_NAME | $COUNT completed"
            fi
        fi
        sleep 60
    done
    
    wait $WORKER_PID
    echo "$SCRIPT_NAME for $DS completed successfully!"
    echo ""
}

for DS in "${DATASETS[@]}"; do
    echo "========================================"
    echo "Initializing dataset: $DS"
    echo "========================================"

    # Calculate total time series for this dataset natively in Python
    TOTAL=$(python -c "
import sys, warnings
warnings.filterwarnings('ignore')
from src.workflows.data_reader import DataWorkflow
from config import N_LAGS, FORECASTING_HORIZON, TEST_SIZE
try:
    ds = DataWorkflow.get_from_gluonts('$DS')
    train, _, _ = DataWorkflow.train_test_split(dataset=ds, n_lags=N_LAGS, horizon=FORECASTING_HORIZON['$DS'], test_size=TEST_SIZE)
    print(len(train))
except Exception:
    print(0)
")

    run_with_progress "run_models.py" "assets/results/by_series" "$TOTAL"
    run_with_progress "run_models_on_extra.py" "assets/results/extra_by_series" "$TOTAL"
    
    if [ "$DS" = "nn5_daily_without_missing" ]; then
        run_with_progress "run_variants.py" "assets/results/variants" "$TOTAL"
        run_with_progress "run_sensitivity.py" "assets/results/sensitivity" "$TOTAL"
    else
        echo "Skipping run_variants.py and run_sensitivity.py for $DS (authors only evaluated these on nn5_daily)"
    fi

    echo "All scripts for $DS finished!"
done
