# Replication Log: Resampling Strategies for Imbalanced Time Series Forecasting

This log tracks day-by-day progress of the replication effort.

---

<!-- Add new entries at the TOP of this file (most recent first) -->

## 2026-08-06 SLURM Node Restart Recovery & 48-Core Parallelization Fix

**Time spent**: 1h 15m

### Problem Encountered
1. **Apparent Stall & Reset Runtime**: Job 11245 was submitted 24 hours prior, but `squeue` showed `TIME = 5:05:46` and only 4 datasets completed on disk.
2. **Node Restart Diagnosis**: Cross-referencing `squeue` revealed 3 different user jobs on `cluster-node5` all shared the exact start time (`5:05:46`). `cluster-node5` had rebooted 5 hours prior, and SLURM automatically requeued Job 11245 via `#SBATCH --requeue`. The checkpointing system correctly skipped datasets 1-4.
3. **Single-Thread Bottleneck**: `performanceEstimation()` was invoked without parallelization parameters (`cluster = NULL`), causing it to process all 52 workflows $\times$ 50 Monte Carlo repetitions (2,600 iterations/dataset) sequentially on a **single CPU core**, leaving 47 of the 48 requested CPUs completely idle.
4. **`parallelMap` API Trap**: Passing `cluster = 48` directly to `performanceEstimation()` failed with `Error in if (!missing(cluster) ...): missing value where TRUE/FALSE needed` because `performanceEstimation` expects `cluster = TRUE` and relies on `parallelMap` for backend execution.

### What Was Done & How it Was Fixed
- **Integrated `parallelMap`**: Added `library(parallelMap)` to `Exps.R`.
- **Configured Forking Backend**: Used `parallelStartMulticore(cpus = ncores)` with `ncores <- as.numeric(Sys.getenv("SLURM_CPUS_PER_TASK", "48"))` before `performanceEstimation()` and `parallelStop()` immediately after.
- **Enabled Cluster Flag**: Set `cluster = TRUE` in `performanceEstimation()` to activate all 48 Linux fork worker threads.

### Results
- Workflows are now parallelized across all 48 CPU cores.
- Processing time per dataset dropped from **~5 hours down to 10-15 minutes**.

---

## 2026-08-05 Cluster Environment Resolution & Successful Execution

**Time spent**: 2h 30m

### What was done
- **Environment & Dependency Resolution**:
  - Diagnosed `performanceEstimation` CRAN archival issue: updated `r_pkgs.txt` to install directly from `github:cran/performanceEstimation`.
  - Solved `UBL` compilation failures caused by missing geospatial C++ system libraries (GDAL, GEOS, PROJ) by adding `r-sf`, `r-lwgeom`, and `r-ranger` to `conda_pkgs.txt` for binary installation via `micromamba`.
  - Patched `setup_r_env.sh` with `export MAMBA_USE_LOCKFILES=false` and `export CONDA_USE_LOCKFILES=false` to eliminate NFS network drive lockfile hangs in `micromamba`.
- **SLURM Quota Tuning**:
  - Resolved `QOSMaxMemoryPerUser` pending block by tuning memory allocation from 128G down to 64G while keeping 48 CPUs (`#SBATCH --cpus-per-task=48`, `#SBATCH --mem=64G`).
- **R Code & Path Fixes**:
  - Fixed path typo in `Exps.R` line 2499 from `src/original/R_Code/Data/data_NM_PB_LT_DSAA2016.Rdata` to `src/original/Data/data_NM_PB_LT_DSAA2016.Rdata`.
  - Removed invalid `, evaluator.pars=list(keepTrain=FALSE)` from `EstimationTask("totTime", ...)` in `Exps.R` which caused `regressionMetrics` to crash after 50 repetitions.
- **Execution Verification**:
  - Confirmed batch job submission and verified live execution running smoothly across all 24 datasets.

### What worked
- Setting `MAMBA_USE_LOCKFILES=false` completely eliminated cluster NFS freezes.
- Pre-installing `r-sf` via `conda-forge` resolved all C++ spatial dependency compilation errors for `UBL`.
- 48 CPUs with 64GB RAM fit perfectly within the cluster QOS memory quota.

### Exact Execution Sequence Used

#### 1. Mac Terminal (Sync Code & Data)
```bash
rsync -avz /Users/joaopms/Documents/Projeto_Mestrado/experiments/002_ts_resampling_strategies/ jpms5@slurm-client1.cin.ufpe.br:~/Projeto_Mestrado/experiments/002_ts_resampling_strategies/
```

#### 2. Cluster Terminal (Environment Build & Job Submission)
```bash
# Connect to cluster
ssh jpms5@slurm-client1.cin.ufpe.br

# Start interactive tmux session for safety
tmux new -s env_setup

# Build environment (if not already built)
bash ~/Projeto_Mestrado/experiments/010_model_selection_ts/setup_r_env.sh exp002_env ~/Projeto_Mestrado/experiments/002_ts_resampling_strategies/conda_pkgs.txt ~/Projeto_Mestrado/experiments/002_ts_resampling_strategies/r_pkgs.txt

# Install archived performanceEstimation package
eval "$(micromamba shell hook --shell bash)"
micromamba activate exp002_env
Rscript -e 'if (!requireNamespace("remotes", quietly = TRUE)) install.packages("remotes", repos="https://cloud.r-project.org/"); remotes::install_github("cran/performanceEstimation", upgrade="never")'

# Navigate to experiment and submit SLURM job
cd ~/Projeto_Mestrado/experiments/002_ts_resampling_strategies
mkdir -p logs
sbatch run_apuana.slurm
```

#### 3. Monitoring
```bash
# Stream live execution output
tail -f logs/exp002_*.out

# Track completed dataset count (out of 24)
ls src/adapted/results/data/results_dataset_*.Rdata 2>/dev/null | wc -l
```

### Next steps
- Monitor job until all 24 datasets complete.
- Execute `Rscript src/adapted/merge_results.R` to consolidate `.Rdata` outputs.
- Run `PairedComparisons.R` to extract final performance rankings and metrics.


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

### Next steps (Where we left off)
Currently, the cluster environment setup failed because `r-performanceestimation` was in `conda_pkgs.txt` but doesn't exist on conda-forge. We fixed the configuration files locally but need to deploy them to the cluster and rebuild the environment.

When returning, follow this EXACT sequence:

#### 1. Push fixed config to cluster (Run on MAC terminal)
```bash
rsync -avz /Users/joaopms/Documents/Projeto_Mestrado/experiments/002_ts_resampling_strategies/conda_pkgs.txt jpms5@slurm-client1.cin.ufpe.br:~/Projeto_Mestrado/experiments/002_ts_resampling_strategies/
rsync -avz /Users/joaopms/Documents/Projeto_Mestrado/experiments/002_ts_resampling_strategies/r_pkgs.txt jpms5@slurm-client1.cin.ufpe.br:~/Projeto_Mestrado/experiments/002_ts_resampling_strategies/
```

#### 2. Clean broken environment and rebuild (Run on CLUSTER terminal)
```bash
# 1. Connect
ssh jpms5@slurm-client1.cin.ufpe.br

# 2. Start a fresh tmux session
tmux new -s env_setup

# 3. Wipe the corrupted partial environment
rm -rf ~/micromamba/envs/exp002_env

# 4. Run the setup script again
bash ~/Projeto_Mestrado/experiments/010_model_selection_ts/setup_r_env.sh exp002_env ~/Projeto_Mestrado/experiments/002_ts_resampling_strategies/conda_pkgs.txt ~/Projeto_Mestrado/experiments/002_ts_resampling_strategies/r_pkgs.txt
```

*Note: You can safely detach from tmux using `Ctrl+B`, release, then `D`.*
*To reattach later and check progress, run: `tmux attach -t env_setup`*

#### 3. Submit Job (Run on CLUSTER terminal)
Once the environment finishes building successfully:
```bash
cd ~/Projeto_Mestrado/experiments/002_ts_resampling_strategies
sbatch run_apuana.slurm
tail -f logs/exp002_*.out
```

- After completion, execute `Rscript src/adapted/merge_results.R` locally in the activated environment.
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
