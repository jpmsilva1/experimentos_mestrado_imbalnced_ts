#!/bin/bash
#SBATCH --job-name=p3_internal
#SBATCH --output=logs/p3_internal_%j.out
#SBATCH --error=logs/p3_internal_%j.out
#SBATCH --partition=long-simple
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=24
#SBATCH --mem=120G
#SBATCH --time=7-00:00:00

set -e  # Halt immediately on any error

# Create logs directory if it doesn't exist
mkdir -p logs

# Activate the R environment
eval "$(micromamba shell hook --shell bash)"
micromamba activate paper_003_env

echo "=== Step 1: Installing archived GitHub dependencies ==="
Rscript -e "
  pkgs <- c('DMwR', 'DMwR2', 'UBL')
  installed <- rownames(installed.packages())
  missing <- pkgs[!pkgs %in% installed]
  if (length(missing) > 0) {
    cat('Installing missing:', paste(missing, collapse=', '), '\n')
    remotes::install_github(paste0('cran/', missing), upgrade='never')
  } else {
    cat('All archived deps already installed\n')
  }
"

echo "=== Step 2: Installing local patched uba ==="
# Remove stale macOS (ARM64) object files so Linux linker gets clean x86_64 objects
find scratch/uba/src -name "*.o" -delete
find scratch/uba/src -name "*.so" -delete
R CMD INSTALL scratch/uba
Rscript -e "library(uba); cat('uba OK\n')"

echo "=== Step 3: Installing STResamplingDSAA ==="
R CMD INSTALL src/original
Rscript -e "library(STResamplingDSAA); cat('STResamplingDSAA OK\n')"

echo "=== Running Phase 2: Patch Internal Tuning ==="
cd src/original/inst
Rscript patch_internal.R

echo "=== Done ==="
