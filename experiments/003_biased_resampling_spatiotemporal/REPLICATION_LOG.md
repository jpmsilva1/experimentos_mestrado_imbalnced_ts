# Replication Log: Biased Resampling Strategies for Imbalanced Spatio-Temporal Forecasting

This log tracks day-by-day progress of the replication effort.

---

<!-- Add new entries at the TOP of this file (most recent first) -->

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
