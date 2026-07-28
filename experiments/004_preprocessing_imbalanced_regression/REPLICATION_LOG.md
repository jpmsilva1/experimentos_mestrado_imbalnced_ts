# Replication Log: Pre-processing Approaches for Imbalanced Distributions in Regression

**Objective**: Replicate the core experiments from Branco et al. (2019) to evaluate the impact of data pre-processing strategies (RU, RO, GN, SMOTE, IS) on imbalanced regression tasks across LM, RF, SVM, and NNET algorithms using Utility-based F-measure (ubaF).

---

## Phase 1: Code Audit & Initial Setup (2026-07-10 to 2026-07-24)
- **Objective**: Scaffold the environment, analyze the original codebase, and identify dependencies.
- **Repository Structure**: Analyzed the original `R_Code` directory and identified entry points for LM, MARS, NNET, RF, and SVM (`expsIS.R`).
- **Dependencies Audit**: 
  - Identified `performanceEstimation`, `UBL`, `e1071`, `randomForest`, `nnet` as stable.
  - `DMwR` was deprecated and `uba` required a pinned local installation (v0.7.7 from a tar.gz).
- **Execution Graph**: Mapped the execution flow: `expsIS.R` -> imports `AuxsIS.R` -> loads `DataSets15.Rdata` -> saves `.Rdata` objects containing grid search results.

## Key Discoveries & Architectural Quirks
To ensure no technical context is lost for future replication attempts, the following critical undocumented issues were discovered and solved during this replication:
1. **The UBL/Geospatial Dependency Hell**: The original `UBL` package fails to compile on modern macOS arm64 due to heavy, deprecated geospatial dependencies (`sf`, `gstat`, `sp`, `automap`). **Hack applied**: We cloned the package and completely ripped out the spatio-temporal modules (which are irrelevant to tabular regression), allowing it to compile cleanly.
2. **The `ImpSampRegress` Deprecation**: Modern versions of `UBL` silently renamed the Importance Sampling function to `WERCSRegress`. The original code crashes until this global rename is applied across all scripts.
3. **Missing NNET Workflows**: The original repo provides a unified `AuxsIS.R`, but it is missing the Neural Network workflows. We had to dig into `R_Code/NNET/AuxsIS.R` to extract 327 lines of hardcoded NNET strategies and inject them into our unified file.
4. **Missing Extraction Code**: The authors provided the PDF figures and the raw `.Rdata` execution grids, but *completely omitted* the R scripts used to extract the metrics and build the tables. We had to reverse-engineer the `performanceEstimation` object structure to build `extract_results.R`.

## Phase 2: Environment Setup & Smoke Testing (2026-07-24)
- **Objective**: Build a stable execution environment and resolve dependency hell.
- **Environment**: Created a Conda environment (`exp004`) running R 4.2.3 on macOS arm64.
- **UBL Patching (Hack)**: Cloned and heavily modified the `paobranco/UBL` package. Ripped out heavy geospatial dependencies (`sf`, `gstat`, `sp`, `automap`, `stars`) that were irrelevant for tabular regression tasks but were causing fatal C++ compilation failures.
- **Smoke Test**: Executed a small-scale test to ensure the patched environment successfully ran the evaluation framework.

## Phase 3: Model Execution & Bug Fixing (2026-07-24 to 2026-07-28)
- **Objective**: Execute the full experimental grid search for all models across the 15 datasets.
- **Bug Fix 1 (UBL Compatibility)**: `ImpSampRegress` failed due to modern `UBL` deprecations. Updated the global `AuxsIS.R` to use the modern equivalent function `WERCSRegress`.
- **Bug Fix 2 (Parallelization)**: Installed `doParallel` and regex-stripped stray parentheses `)` in the original `expsIS.R` files that were causing syntax errors.
- **Bug Fix 3 (NNET Workflows)**: The original authors maintained distinct `AuxsIS.R` files per model. The NNET script crashed because `WFnone_nnet_s1_d0` was missing. Extracted 327 lines of custom NNET workflows from the original repository and injected them into our `src/adapted/AuxsIS.R`.
- **Resource Management**: Parallelized execution using `doParallel(cores=4)` to balance thermal throttling (~74°C). Wrapped all runs inside macOS `caffeinate -dimsu -w PID &` to prevent App Nap and Deep Sleep interruptions during multi-day processes.
- **Execution Completion**: 
  - Random Forest (RF) completed in ~23 hours.
  - Support Vector Machines (SVM) completed in ~38 hours, successfully handling massive 120MB datasets (`.cpuSm`, `.heat`).
  - Neural Networks (NNET) completed successfully.

## Phase 4: Result Extraction (2026-07-28)
- **Objective**: Convert binary R grid objects into a single parsable CSV.
- **Missing Code**: Discovered that the original repository omitted the scripts used to extract the results and build the paper's tables.
- **Custom Extractor**: Developed `src/adapted/extract_results.R` to programmatically load every `performanceEstimation` `.Rdata` blob and extract the average Cross-Validation scores for F-measure (`ubaF`), Precision (`ubaprec`), and Recall (`ubarec`).
- **Success**: Consolidated all execution data into a single 5,746-row CSV containing the aggregated results across all algorithms, strategies, and datasets.

## Generated Files & Artifacts Directory
This replication effort produced the following key files. This section exists so future researchers understand exactly what each file does:
- **`results/LM/*.lm.Rdata`**: Binary `performanceEstimation` R objects containing the iteration scores for Linear Models.
- **`results/NNET/*.nnet.Rdata`**: Binary `performanceEstimation` R objects. These contain the raw 2x10-Fold Cross Validation iteration scores for Neural Network models across all datasets and pre-processing strategies.
- **`results/RF/*.randomForest.Rdata`**: Binary R objects containing the exact same iteration scores, but for the Random Forest models.
- **`results/SVM/*.svm.Rdata`**: Binary R objects containing the iteration scores for Support Vector Machine models.
- **`src/adapted/extract_results.R`**: Custom R script designed to automate the missing extraction step. It loops through all `.Rdata` objects and calculates the mean metrics.
- **`results/tables/final_metrics.csv`**: The canonical dataset (5,746 rows). Contains structured aggregated results (`Dataset`, `Algorithm`, `Strategy`, `Variant`, `Workflow`, `ubaF`, `ubaprec`, `ubarec`). This file serves as the baseline for the final validation against the paper's original tables.

## Phase 5: Validation against Original Paper (Complete)
- **Objective**: Compare our replicated `.csv` results against the official results reported in **Branco et al. (2019)**.
- **Methodology**: Evaluated against the original target values parsed from the Agent-Native Research Artifact (ARA) `PAPER.md` found in the local Obsidian vault.
- **Validation Outcome**: 
  - Calculated exact `ubaF` match tables for LM on datasets `Abalone` (DS2) and `a1` (DS5) with mostly ≤ 2% relative differences, easily within scientific tolerance bounds.
  - Calculated algorithmic win rates over baseline using a 13-dataset sweep, confirming identical 100% win rate for SVM with `WFIS` (WERCS) just like in the original paper, reinforcing their core claim.
  - Full statistical tables are now available in the [README.md](file:///Users/joaopms/Documents/Projeto_Mestrado/experiments/004_preprocessing_imbalanced_regression/README.md).
- **Next Step**: Bridge 4 (Session Save & Wrap-up).
