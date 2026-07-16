#!/bin/bash

# Navigate to the repository
cd /Users/joaopms/Documents/Projeto_Mestrado/experiments/013_ts_augmentation_imbalanced/src/original

# Activate the conda environment
source /Users/joaopms/miniconda3/bin/activate
conda activate exp013_tser

# The list of datasets from ALL_DATASETS
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

# Iterate over each dataset
for DS in "${DATASETS[@]}"; do
    echo "========================================"
    echo "Starting runs for dataset: $DS"
    echo "========================================"
    
    echo "Running run_models.py for $DS..."
    python scripts/run/run_models.py "$DS"
    
    echo "Running run_models_on_extra.py for $DS..."
    python scripts/run/run_models_on_extra.py "$DS"
    
    echo "Running run_variants.py for $DS..."
    python scripts/run/run_variants.py "$DS"
    
    echo "Running run_sensitivity.py for $DS..."
    python scripts/run/run_sensitivity.py "$DS"
done

echo "All runs completed successfully!"
