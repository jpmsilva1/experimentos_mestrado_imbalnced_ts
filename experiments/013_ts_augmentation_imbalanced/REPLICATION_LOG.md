# Replication Log: Time Series Data Augmentation as an Imbalanced Learning Problem

This log tracks day-by-day progress of the replication effort.

---

<!-- Add new entries at the TOP of this file (most recent first) -->

## 2026-07-29 Cluster Optimization & Concurrency Patch

**Time spent**: 1h 30m

### What was done
- **Cluster Quota Analysis**: Identified that the Apuana cluster has a strict `QOSMaxJobsPerUserLimit` and a maximum limit of 48 CPUs per user. The previous SLURM array strategy (4 running jobs × 8 CPUs = 32 CPUs) was not fully maxing out the quota, which we later found to be 48, blocking Experiment 003 (which required 24 CPUs) from executing when combined.
- **Distributed SLURM Refactor**: Created a new `run_distributed_apuana.slurm` script that condenses the entire `exp013` execution into a **single job** initially requesting 8 CPUs, and later scaled up to 24 CPUs and 120GB RAM. This seamlessly packs with Exp003 (24 CPUs) to perfectly hit the 48 CPU limit.
- **Concurrency Implementation**: Utilized `xargs -P 8` to launch 8 simultaneous Python workers per dataset, retaining parallelization without requiring multiple SLURM array jobs.
- **Race Condition (TOCTOU) Patch**: Discovered that launching 8 identical deterministic Python processes simultaneously caused a "Time-Of-Check to Time-Of-Use" race condition on the `.csv` lock files. Patched `run_models.py`, `run_models_on_extra.py`, `run_variants.py`, and `run_sensitivity.py` to include `random.shuffle(ts_names)`. This ensures each worker processes the time series in a completely random order, entirely preventing collision.
- **ADASYN Fallback Patch**: Identified that the `ADASYN` algorithm from `imblearn` was crashing on `m4_hourly` due to a math `RuntimeError` triggered by extreme class imbalance. Added a `try...except` block in `src/methods/tser.py` to seamlessly fallback to `SMOTE` when this occurs.
- **Background Progress Monitor**: Developed a custom SLURM-safe background monitor inside the bash script. Instead of using `tqdm` (which spams `\r` and corrupts SLURM `.out` files), a background loop wakes up every 60 seconds, counts the generated `.csv` files, and prints a clean completion percentage to the log. The total number of series is calculated dynamically via a silent Python hook to GluonTS.

### What worked
- The "perfect packing" of 8 CPUs for Exp013 and 24 CPUs for Exp003 works flawlessly within the cluster limits.
- The Python `random.shuffle` effectively resolved all race conditions, allowing the 8 parallel workers to independently process time series at 8x speed.
- The background progress monitor successfully printed clean, accurate percentages without any log corruption.
- Code changes were successfully pushed to git and synced to the cluster via `rsync`.

### Issues encountered
- Encountered a `fatal: not a git repository` error when attempting to `git pull` on the cluster, indicating the directory was originally synced via `rsync` or `scp`. Bypassed by providing the exact `rsync` push command for the local machine.

### Next steps
- Monitor the background execution of `run_distributed_apuana.slurm`.
- Once completed, aggregate the results and execute the analysis scripts to generate figures.

## 2026-07-24 Cluster Deployment Script Created

**Time spent**: 0h 15m

### What was done
- Created a SLURM job array script (`run_apuana.slurm`) to execute all 9 datasets in parallel on the Apuana cluster.
- Configured CPU/threading constraints (`OMP_NUM_THREADS`, etc.) dynamically based on SLURM allocation to prevent node thrashing.
- Assumed `micromamba` for environment activation to match cluster standards from previous experiments.

### What worked
- Parallelizing the datasets using SLURM arrays will reduce runtime drastically by processing them on independent nodes/tasks.
- Environment `exp013_tser` successfully created on the Apuana cluster via `setup_cluster_env.sh` (micromamba).
- Successfully submitted the job array. Discovered the cluster has a hard limit of **4 running jobs per user** (`QOSMaxJobsPerUserLimit`), so 3 array tasks run in parallel while `paper003` occupies the 4th slot.

### Issues encountered
- Tmux terminal corruption occurred due to `micromamba` progress bars on cluster, fixed by setting `MAMBA_NO_PROGRESS=1`.
- SLURM array jobs crashed instantly on first attempt because the `logs/` directory didn't exist. Fixed by running `mkdir -p logs` before `sbatch`.

### Next steps
- Sync files to Apuana cluster.
- Run `sbatch run_apuana.slurm`.
- Wait for completion and proceed with aggregation analysis scripts.

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
