#!/bin/bash
# Wrapper to run R scripts safely inside conda
eval "$(conda shell.bash hook)"
conda activate exp004

echo "Running R script: $1"
Rscript "$1"
