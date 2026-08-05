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
