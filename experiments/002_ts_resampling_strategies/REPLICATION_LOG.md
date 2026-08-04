# Replication Log: Resampling Strategies for Imbalanced Time Series Forecasting

This log tracks day-by-day progress of the replication effort.

---

<!-- Add new entries at the TOP of this file (most recent first) -->

## 2026-08-04 Apuana Cluster Adaptation

**Time spent**: 1h 00m

### What was done
- Adapted the original evaluation script (`Exps.R`) to run efficiently on the Apuana SLURM cluster.
- Replaced the single-dataset hardcode with a sequential loop over all 24 datasets to fit within the cluster's hard limit of 4 concurrent jobs per user.
- Added file existence checks (checkpointing) to automatically resume if the job crashes or hits wall time.
- Implemented aggressive garbage collection (`gc()`) and object removal (`rm()`) after each dataset to prevent the memory leaks previously observed.
- Created `run_apuana.slurm` requesting 1 node, 24 CPUs, and 128GB of RAM for the `long-simple` partition.
- Added `merge_results.R` to combine the individual dataset results into a single object for downstream metric computation.
- Verified in the `completed_experiments_dossier.tex` that the authors originally ran this on an 8-core AMD Opteron with 32GB RAM.

### What worked
- Sequential approach guarantees compliance with cluster limits and resolves the R environment duplication issues seen in parallel job array attempts.

### Issues encountered
- Massive memory explosions in earlier parallel attempts required shifting to a single-job sequential workflow with manual garbage collection.

### Next steps
- Upload the `src/adapted/` folder and `run_apuana.slurm` to the Apuana cluster.
- Submit the SLURM job (`sbatch run_apuana.slurm`) when a queue slot is available.
- After completion, execute `Rscript src/adapted/merge_results.R`.
- Proceed with `PairedComparisons.R` to generate final evaluation metrics.

## 2026-07-13 Fix bugs and run experiments

**Time spent**: 1h 30m

### What was done
- Setup proper C and Fortran compilers on the ARM64 Mac environment.
- Fixed `uba` C compilation error by cloning the package from GitHub, modifying `init.c` to allow dynamic symbols and `util.h` to fix a `bool` typedef conflict.
- Fixed the `C.perc` multi-bump parameter issue in the custom `smoteRegress` functions in `Exps.R` to properly handle cases where the dataset has more than 2 relevance bumps.
- Successfully ran `Exps.R`, `PairedComparisons.R`, and `OptParmsSearch.R`.
- Extracted and saved the evaluation tables and runtime comparisons to CSV files.

### What worked
- Re-compiling the `uba` package from source locally fixed all dynamic loading issues.
- The experiments and paired comparisons successfully completed after the code was patched.

### Issues encountered
- The old version of `uba` had pre-compiled `.o` and `.so` files for Intel Macs that failed on ARM.
- The `smoteRegress` functions in `Exps.R` assumed a rigid structure for `C.perc` that broke down when evaluating the parameter grid for multi-bump time series.

### Next steps
- Review and plot the exported result tables.

## 2026-07-13 Code Clone and Setup

**Time spent**: 0h 15m

### What was done
- Cloned the original paper repository ([nunompmoniz/TSResampStrat_JDSA2017](https://github.com/nunompmoniz/TSResampStrat_JDSA2017)) into [original](file:///Users/joaopms/Documents/Projeto_Mestrado/experiments/002_ts_resampling_strategies/src/original/).
- Cleared git history (`.git` folder) in `src/original/` to allow tracking code inside the parent repository.
- Linked workspace configuration path for R and Python in `.vscode/settings.json`.

### What worked
- Cloned repository successfully.
- Verified file structure.

### Issues encountered
- None.

### Next steps
- Verify the local R installation can execute the author's scripts.
- Identify target results to replicate.

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
