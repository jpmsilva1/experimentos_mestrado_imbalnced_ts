# Replication Log: Pre-processing Approaches for Imbalanced Distributions in Regression

This log tracks day-by-day progress of the replication effort.

---

<!-- Add new entries at the TOP of this file (most recent first) -->
## 2026-07-24 Phase 3: Model Execution & Bug Fixing
- **Fixed `ImpSampRegress` error**: The original script failed because `ImpSampRegress` was renamed to `WERCSRegress` in modern versions of the `UBL` package. Updated the global `AuxsIS.R` to use `WERCSRegress`. Linear Model (LM) successfully reached 100% completion.
- **Fixed `doParallel` error**: Installed the missing `doParallel` package into the `exp004` Conda environment to enable multi-core execution for RF, SVM, and NNET.
- **Fixed Syntax Typo**: The original authors left an extra parenthesis `)` in line 64 of `expsIS_RF.R`, `expsIS_SVM.R`, and `expsIS_NNET.R`. Stripped it via regex.
- **Temperature & Resource Management**: Running `registerDoParallel(cores=7)` locally proved too intensive for the Mac. As established in experiment `012`, reduced the core limit to `cores=4` to keep the temperature stable at ~74°C while maximizing throughput. Wrapped the execution in a background OS `caffeinate` lock (`caffeinate -dimsu -w PID &`) to prevent the Mac from sleeping overnight while Random Forest evaluates across the 15 datasets.


## 2026-07-24 Phase 2: Environment Setup & Smoke Test (COMPLETED)
- Created Conda environment `exp004` with R 4.2.3.
- Resolved ClobberError and long hanging environment solvers by adapting `UBL`.
- **Hack applied**: Cloned `paobranco/UBL`, patched `NAMESPACE` and `DESCRIPTION` to rip out heavy geospatial dependencies (`sf`, `gstat`, `automap`, `sp`, `stars`) because they are only used for Spatio-Temporal Resampling which is irrelevant for tabular regression tasks in this paper. This saved gigabytes of C++ system libraries and allowed seamless installation.
- Script `smoke_test.R` passed successfully.

## 2026-07-24 Phase 1: Code Audit

### Entry Points
- `R_Code/LM/expsIS.R`: Runs LM model experiments
- `R_Code/MARS/expsIS.R`: Runs MARS model experiments
- `R_Code/NNET/expsIS.R`: Runs NNET model experiments
- `R_Code/RF/expsIS.R`: Runs RF model experiments
- `R_Code/SVM/expsIS.R`: Runs SVM model experiments

### Execution Graph
`expsIS.R`
  → imports `AuxsIS.R`
  → reads `DataSets15.Rdata` [path: likely hardcoded to load("...DataSets15.Rdata")]
  → writes experiment results [path: likely hardcoded in RData files]

### Red Flags
- ❌ HARDCODED PATH: Data loading paths might be hardcoded or expect specific working directory.
- ❌ KNOWN DEPRECATED: `DMwR` package has been archived from CRAN.

### Dependency Pre-Audit
- `DMwR`: ❌ KNOWN DEPRECATED
- `performanceEstimation`: ✅ STABLE
- `UBL`: ✅ STABLE
- `uba`: ⚠️ PINNED OLD VERSION (v0.7.7 tar.gz from external URL)
- `e1071`: ✅ STABLE
- `randomForest`: ✅ STABLE
- `earth`: ✅ STABLE
- `nnet`: ✅ STABLE

### Target Results
[User to define specific target tables/figures to reproduce from the paper]

### Primary Language Detected
R
→ Loading: references/lang-r.md

## 2026-07-24 Environment Profile
- **OS/Arch**: macOS arm64
- **Paper knowledge**: URL only
- **Project structure**: Existing: /Users/joaopms/Documents/Projeto_Mestrado/experiments/004_preprocessing_imbalanced_regression
- **Available skills**: ara-compiler, ponytail
- **Platform doc**: references/platform-apple-silicon.md
- **Language doc**: pending detection

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
