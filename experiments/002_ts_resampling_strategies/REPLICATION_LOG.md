# Replication Log: Resampling Strategies for Imbalanced Time Series Forecasting

This log tracks day-by-day progress of the replication effort.

---

<!-- Add new entries at the TOP of this file (most recent first) -->

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
