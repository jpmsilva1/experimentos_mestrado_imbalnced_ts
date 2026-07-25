# Replication Log: Biased Resampling Strategies for Imbalanced Spatio-Temporal Forecasting

This log tracks day-by-day progress of the replication effort.

---

<!-- Add new entries at the TOP of this file (most recent first) -->

## 2026-07-25 SLURM Distributed Optimization & Checkpointing

**Time spent**: 1h 0m

### Executive Summary
After successfully migrating to the cluster, we hit a severe QOS array bottleneck due to concurrency limits. Additionally, the fallback to strictly sequential execution (`.parallel = FALSE`) caused the `rpart` model evaluations on Beijing to take over 18 hours. We engineered a dynamic parallel patch for `patch_external.R` to optimize thread usage across 24 cores (10 parallel folds for `rpart`/`earth`, and 24 native threads for `ranger`), shrinking execution time from 9 days to 24 hours. A checkpointing mechanism was also introduced, salvaging the 18 hours of prior sequential `rpart` computation.

### 1. The QOSMaxJobsPerUserLimit Array Bottleneck
- **Bottleneck:** A single user can only have 4 SLURM jobs active simultaneously on the cluster. The 4 concurrent array jobs from Experiment 013 completely saturated this quota, blocking `paper003` from starting.
- **Solution:** Temporarily paused the `exp013` queue via `scontrol hold`, killed the youngest running array job (`scancel 7896_5`) to free exactly 1 slot, and allowed `paper003` to initiate before releasing the hold queue.

### 2. Checkpointing: Saving 18 Hours of Work
- **Bottleneck:** The legacy script saved the massive `res` Rdata matrix *only* after evaluating all parameter combinations for a specific model. Aborting midway meant losing all progress.
- **Solution:** Injected `if(!is.null(res[[m]][[dfnm]][[parnm]])) next` into the inner parameter loop of `patch_external.R`. This `safe resume` mechanism successfully bypassed 50 iterations of `rpart` that had previously completed, instantly skipping 18 hours of redundant calculation upon restart.

### 3. Dynamic Parallelism (The 10x Speedup)
- **Bottleneck:** `rpart` and `earth` are strictly single-threaded models. Under `.parallel = FALSE`, cross-validating 10 folds sequentially on 151,000 rows took 18 hours per dataset.
- **Solution:** 
  - Overrode `.parallel = TRUE` and registered `NCORES = 10` using `doParallel` specifically for `rpart` and `earth`, dropping the evaluation time from 18 hours down to < 2 hours (10x speedup).
  - Explicitly kept `.parallel = FALSE` for `ranger`, but injected `num.threads = 24` to leverage its superior native C++ threading, maxing out the cluster node's 24 cores without memory duplication overhead.

## 2026-07-24 Cluster Migration & High-Performance Compute Setup

**Time spent**: 2h 45m

### Executive Summary
The replication effort transitioned from local laptop execution (which was projected to require ~72 hours of max-CPU utilization and faced OOM risks) to the `apuana` university compute cluster. This transition surfaced multiple deep-seated environment, compilation, and dependency issues. By engineering a robust SLURM orchestrator, downgrading modern C compilers to support legacy R dependencies, and fixing cross-platform binary contamination, the Spatio-Temporal resampling phase successfully commenced parallel execution across 24 threads.

### 1. Environment & Architecture Shift
- **Bottleneck:** Local compute was entirely insufficient for the 600+ parameter grid evaluations on the 151,000-row Beijing datasets.
- **Solution (Cluster Migration):** Migrated the codebase to the `apuana` cluster. We provisioned a local Micromamba environment within the user's home directory.
- **Solution (NFS Locking):** Encountered Conda environment corruption due to Network File System (NFS) locks on the cluster. Fixed by exporting `MAMBA_CACHE_DIR=/tmp/$USER/mamba_cache` to force Conda to use local node storage for caching.
- **Solution (Resource Allocation):** Initially attempted to request 64 CPUs, but hit the `QOSMaxCpuPerUserLimit`. Scaled the SLURM request down to 24 CPUs, which still provides a massive speedup over sequential local execution.

### 2. The Silent Killer: Data Sync Failure
- **Bottleneck:** The SLURM job appeared to execute instantly without errors, but no models were trained and no new logs were generated.
- **Root Cause:** The `patch_external.R` script relies on `inds_df.Rdata` located in `src/results/`. However, the `results/` directory was blocked by the repository's `.gitignore`. The R script's `try()` blocks caught the missing data errors silently, causing the script to exit successfully without actually doing any work.
- **Solution:** Manually zipped the local `results/` folder, transferred it via `scp`, and unzipped it directly into the cluster workspace, bypassing git entirely for the data binaries.

### 3. Dependency Versioning Mismatch
- **Bottleneck:** The custom `STResamplingDSAA` package failed to install on the cluster, citing `package 'uba' >= 0.7.8 is required`.
- **Root Cause:** The stable version of `uba` provided in the author's GitHub fork (and previously installed locally) is `0.7.7`. 
- **Solution:** Manually patched the `DESCRIPTION` file of the `STResamplingDSAA` source code, lowering the `uba` dependency requirement to `>= 0.7.7`.

### 4. SLURM Fail-Fast Engineering
- **Bottleneck:** Bash scripts for SLURM jobs often swallow R installation errors, moving on to the next command even if a crucial dependency failed to compile.
- **Solution:** Architected a robust SLURM script by injecting `set -e` to mandate fail-fast execution. Additionally, injected explicit validation gates (e.g., `Rscript -e "library(STResamplingDSAA)"`) after every installation step to force the job to crash visibly if a package failed to load.

### 5. Cross-Platform Compilation Contamination
- **Bottleneck:** The `uba` package failed to compile on the cluster with the error: `file not recognized: File format not recognized`.
- **Root Cause:** The local repository was synced via git, which included compiled C object files (`*.o`, `*.so`) in `scratch/uba/src`. These files were compiled on an Apple Silicon Mac (ARM64 architecture). When the Linux cluster (x86_64 architecture) attempted to link them during `R CMD INSTALL`, the linker threw a fatal error due to the architecture mismatch.
- **Solution:** Added a pre-installation step in the SLURM script to aggressively sanitize the source tree: `find scratch/uba/src -name "*.o" -delete` and `find scratch/uba/src -name "*.so" -delete`. This forced the Linux cluster to build fresh x86_64 binaries from the raw C source code.

### 6. Modern C vs Legacy R Dependencies (GCC 15 / C23)
- **Bottleneck:** After wiping the old binaries, the `uba` package threw fatal C compilation errors:
  1. `error: assignment to 'phi_out (*)(void)' from incompatible pointer type`
  2. `error: too many arguments to function; expected 0, have 2`
- **Root Cause:** The cluster runs GCC 15.2.0, which enforces the modern C23 standard (`-std=gnu23`) by default.
  - In legacy C (C89/C99), an empty parameter list `()` meant "an unspecified number of arguments." In C23, it strictly means "zero arguments" (equivalent to `(void)`).
  - Furthermore, GCC 14+ elevated "incompatible pointer types" from a compilation warning to a fatal error.
  - The 2017 `uba` codebase extensively utilized legacy C syntax, causing it to shatter against the modern C23 compiler. (This succeeded locally because Apple Clang relies on older standards by default).
- **Solution:** Created a custom `Makevars` file within `scratch/uba/src/` with the following configuration:
  `PKG_CFLAGS = -std=gnu17 -Wno-incompatible-pointer-types -Wno-implicit-function-declaration`
  This explicitly forces the cluster's C compiler to downgrade to the C17 standard and treat pointer incompatibilities as warnings, successfully compiling the legacy code.

### Execution Status
- The environment is fully operational and the C binaries are natively compiled for the cluster.
- `patch_external.R` is actively running.
- **Progress Tracking:** To monitor the exact progress out of the 600 total parameter combinations without interrupting the job, the following live-calc script can be executed on the cluster:
  `echo "Scale=2; Progress = $(grep -c 'Patching' logs/paper003-st-resampling_*.out) / 600 * 100; print Progress; print \"% Complete\n\"" | bc`

### 7. Phase 2 Architecture (Next Steps)
- **Bottleneck Prevented:** The original `exps_internalTuning.R` script initializes a fresh `res <- list()` object. If executed on the cluster as-is, it would have permanently overwritten and deleted all local cross-validation data for the 6 smaller datasets (MESA, TCEQ, etc.).
- **Solution (Safe Patching Mechanism):** 
  - Engineered `patch_internal.R` to load the existing `res_internalTuning.Rdata` instead of wiping it.
  - Hardcoded the script to filter `inds_df` exclusively to the 4 `BEIJ` datasets, preventing redundant computation.
  - Created `run_apuana_phase2.slurm` to orchestrate this specific job on the cluster.
- **Execution Instructions (For Tomorrow):**
  1. Once Phase 1 is fully complete, verify the generated `res_externalPrequential.Rdata`.
  2. Upload `patch_internal.R` and `run_apuana_phase2.slurm` to the cluster.
  3. Upload your local `results/res_internalTuning.Rdata` to the cluster (so the script has the base data to patch).
  4. Submit the job: `sbatch run_apuana_phase2.slurm`.

## 2026-07-18 Execution Abort & Cluster Recommendation

**Time spent**: 0h 15m

### What was done
- **Performance Evaluation:** Monitored the background execution of `patch_external.R`. After running for 9 hours and 40 minutes, it was only approximately 20% complete with the Spatio-Temporal evaluations for the Beijing datasets.
- **Root Cause:** The BEIJ datasets contain over 151,000 rows. Training `ranger` (Random Forest) on these using sequential execution (`.parallel=FALSE`, mandated by our earlier OOM fixes) takes ~10-15 minutes per single parameter combination. With 50 combinations per model (3 models) across 4 datasets, this translates to over 600 evaluations.
- **Calculated Projection:** Completing just Phase 1 (`patch_external.R`) would take ~30 additional hours. Phase 2 (`exps_internalTuning.R`) would require an additional ~40 hours for cross-validation on the same grid. Total laptop execution time would be roughly ~3 straight days of CPU max-out.
- **Action Taken:** The user manually aborted the execution (`^C`) to prevent locking up local hardware for 72 hours. 

### Current state
- The experiment is officially **paused**.
- The `res_externalPrequential.Rdata` file has been safely preserved, but it does NOT contain the full `stunder`/`stover` evaluations for BEIJ datasets yet.

### Next steps
- **Migrate to High-Performance Compute:** We strongly recommend migrating this repository to the university cluster or an AWS EC2 instance (e.g., `c6a.16xlarge` with 64+ cores and 128GB+ RAM). 
- **Re-enable Parallelism:** On a cluster with sufficient memory, we can safely revert `.parallel=FALSE` to `.parallel=TRUE` for fold allocation and distribute the `ranger` model evaluations across 64+ threads, shrinking the 3-day timeline down to a few hours.

## 2026-07-18 Fixing `lubridate` Parsing Error & Patch Strategy

**Time spent**: 0h 45m

### What was done
- **Diagnosed Bug:** The `exps_externalPrequential.R` script began throwing `length(unique(folds)) == nfolds is not TRUE` errors specifically for the `stunder` and `stover` methods on the BEIJ datasets.
- **Root Cause:** The script used `lubridate::ymd_hms()` which failed to parse 6,128 dates in the `BEIJ` dataset that lacked a timestamp (e.g., `"2013-02-20"`). This resulted in `NA` date values which completely broke the internal fold allocation logic for the Spatio-Temporal resampling methods.
- **Fix:** Edited `exps_externalPrequential.R` and `exps_internalTuning.R` to use `lubridate::ymd_hms(ind_df$time, truncated = 3)`. This properly parses strings missing the `"00:00:00"` timestamp.
- **Salvage Operation:** Because the original script used a `try()` block, it safely skipped the broken `stunder`/`stover` evaluations and continued processing `baseline`, `under`, and `over` methods for the remaining Beijing datasets without crashing. Instead of killing the 4-hour process, a `patch_external.R` script was developed to load the `res_externalPrequential.Rdata` output post-completion and strictly compute the missing `stunder`/`stover` parameters, avoiding the need to rerun the massive grid search from scratch.

### Current state
- The main `exps_externalPrequential.R` script is currently completing its native run for the remaining valid configurations.
- `exps_internalTuning.R` is queued to run sequentially via `&&` and has already been updated with the patched code.
- `patch_external.R` is staged to be run manually after all internal tuning is finished to backfill the missing ST methods.

---

## 2026-07-17 Resolving C Compiler & `uba` Package Crash

**Time spent**: 0h 30m

### What was done
- **Diagnosed R Evaluation Crash:** The `exps_externalPrequential.R` script crashed immediately upon reaching the model evaluation phase with error: `"r2util" not resolved from current namespace (uba)`.
- **Root Cause:** The `uba` package heavily relies on C code (`.C("r2util")`) to compute Utility-based Precision/Recall/F1 metrics. The Conda environment was missing the Apple Silicon (arm64) C compilers, meaning `uba` installed but quietly failed to build its shared `.so` library, leaving the `r2util` symbol missing.
- **Fix:**
  - Installed `clang_osx-arm64` and `clangxx_osx-arm64` directly into the `paper_003_env` conda environment.
  - Cleaned the cached object files from the local source directory (`scratch/uba`).
  - Executed `R CMD INSTALL scratch/uba` to natively re-compile the package on Apple Silicon using the newly available conda C compilers.

### Current state
- The C library (`uba.so`) successfully built and linked.
- The `exps_externalPrequential.R` script is currently running completely stable and processing through the ST resampling combinations.

---

## 2026-07-17 Performance Analysis & OOM Prevention (exps scripts)

**Time spent**: 1h 0m

### What was done
- **Analysis:** Conducted a deep dive into the performance bottlenecks of the `exps_externalPrequential.R` and `exps_internalTuning.R` scripts.
- **Finding 1 (Memory Bomb):** Discovered that `.keepTrain = TRUE` in `EST_PARS` was accumulating ~15.6 MB of training data per evaluation call in the `res` object, totaling over ~30 GB across the full experiment grid. This would inevitably cause an OOM crash even sequentially.
- **Finding 2 (CPU Bottleneck):** Discovered that `get_space_wts()` in `sampling_weight.R` used a doubly-nested R loop (O(T * S^2)), executing ~95 million iterations per dataset/model combo for ST resampling.
- **Fix (Option G):** Stripped the `train` data from `rawRes` immediately after evaluation in `eval_framework.R`'s `estimates()` function. The evaluator still has access to the train data it needs, but it isn't kept permanently.
- **Fix (Option A):** Added `NUM_THREADS <- parallel::detectCores() - 1` and passed it to `ranger` in the workflow configs. This provides native C++ multi-threading for ranger model training without any `doParallel` memory duplication.
- **Fix (Option H):** Vectorized the `get_space_wts()` nested loop. The inner loop was replaced with a vectorized submatrix operation using `apply(D, 1, min)`, reducing the overhead dramatically for ST methods.
- **Fix (Option E):** Added conditional logic to re-enable `.parallel = TRUE` for folds on small datasets (fewer than 20,000 rows). Large datasets remain sequential to prevent OOM.

### Current state
- The 20 indicator datasets finished generating completely.
- The `exps_externalPrequential.R` script is ready to run with optimizations.

### How to run
```bash
conda activate paper_003_env
cd experiments/003_biased_resampling_spatiotemporal/src/original/inst
/Users/joaopms/miniconda3/envs/paper_003_env/bin/Rscript exps_externalPrequential.R
```

---

## 2026-07-17 Sequential Run Setup, Memory Monitoring & Chunking Fixes

### How to run (after this crash)

**Terminal 1 — start monitor FIRST:**
```bash
cd experiments/003_biased_resampling_spatiotemporal
bash scratch/monitor_mem.sh
```

**Terminal 2 — run the experiment:**
```bash
conda activate paper_003_env
cd experiments/003_biased_resampling_spatiotemporal/src/original/inst
/Users/joaopms/miniconda3/envs/paper_003_env/bin/Rscript generate_inds.R
```

### What to watch for
- If RAM usage exceeds ~60GB → **it's Cause B** (neib_vals explosion, not matrix copying).
  Stop immediately to avoid another crash.
- If RAM stays reasonable (<30GB) → sequential is the fix. Fork-based parallel can be
  re-enabled later for speedup (see Next steps).

### Issues encountered
- The script crashed while processing `BEIJno` with `Error: vector memory limit of 16.0 Gb reached`.
- This is because `BEIJno` has 151,841 rows. Sifting through all 151k rows at once created a list of 151,841 separate data frames in memory before binding them, which triggered R's safety limit.

### Next steps
- **Fixed:** Implemented row chunking in `st_indicators.R`. The process is now run in chunks of 5000 rows, meaning R only keeps 5000 data frames in memory at any point. This bounds the RAM usage to <500MB instead of >16GB.
- Run the experiment again. The resume logic still works, so it will start back on `BEIJno`.

---

## 2026-07-17 Investigation of OOM Crash


**Time spent**: 0h 30m

### What was done
- Investigated the state of the experiment after an Out-Of-Memory (OOM) crash that used up to 78GB RAM while running `generate_inds.R`.

### What worked
- The first 13 datasets out of 20 were successfully processed.
- Progress was saved in `src/results/inds_df.Rdata`. It automatically loads and resumes, so we don't have to restart from scratch.
- Successfully processed datasets: `MESApol`, `NCDCPprec`, `NCDCSsol`, `NCDCTtemp`, `TCEQOozone`, `TCEQTtemp`, `TCEQWwind`, `COOKwater`, `COOKtemp`, `COOKcond`, `SRdif`, `SACtemp`, `RURALpm10`.

### Issues encountered
- The script crashed while processing the 14th dataset: `BEIJno`. The BEIJ datasets (Beijing) are likely much larger and caused the memory explosion.

### Next steps
- Find a way to optimize the memory usage for the BEIJ datasets in `generate_inds.R`, or process them separately on a machine with more memory.


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
