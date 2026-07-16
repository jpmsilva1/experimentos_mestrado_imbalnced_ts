# Replication Log: Time Series Data Augmentation as an Imbalanced Learning Problem

This log tracks day-by-day progress of the replication effort.

---

<!-- Add new entries at the TOP of this file (most recent first) -->

## 2026-07-16 Environment Setup & Local Run Deferred

**Time spent**: 2h 0m

### What was done
- Cloned the `experiments-tser` repository into `src/original`.
- Configured the `exp013_tser` Conda environment and successfully compiled `lightgbm` for ARM64 macOS using `conda-forge`.
- Executed hyperparameter optimization and injected best parameters into the LightGBM models.
- Refactored `run_models.py`, `run_models_on_extra.py`, `run_variants.py`, and `run_sensitivity.py` to fix broken relative imports (`codebase.*` -> `src.*`), resolve absolute paths for output directories, and dynamically parse dataset arguments.
- Built a global `run_all.sh` orchestration script to process all 9 datasets.
- Optimized LightGBM initialization to utilize multiple CPU cores (`n_jobs=7`).

### What worked
- Fixing the environment, compiling LightGBM, and refactoring the scripts allowed the code to execute locally without crashing.

### Issues encountered
- The time complexity of evaluating all time series inside the 9 datasets sequentially is far too high for a local machine (estimated 6-12+ hours). 

### Next steps
- **CLUSTER EXECUTION:** Deploy the `run_all.sh` pipeline on a distributed computational cluster (e.g. SLURM) to handle the massive compute load.
- Run the analysis scripts in `scripts/run_analysis/` to aggregate results and generate plots once cluster execution is complete.

## 2026-07-10 Initial Setup

**Time spent**: 0h 0m

### What was done
- Scaffolded experiment folder from template

### What worked
- N/A

### Issues encountered
- None

### Next steps
- Clone original code
- Set up environment
- Identify target results to replicate
