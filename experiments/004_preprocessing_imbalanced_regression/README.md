# Pre-processing Approaches for Imbalanced Distributions in Regression

## Paper Metadata

| Field | Value |
|-------|-------|
| **Authors** | Paula Branco, Luís Torgo, Rita P. Ribeiro |
| **Year** | 2019 |
| **Venue** | Neurocomputing (Volume 343, Pages 76-99) |
| **DOI/URL** | [10.1016/j.neucom.2018.11.100](https://doi.org/10.1016/j.neucom.2018.11.100) |
| **Original Code** | [paobranco/Pre-processingApproachesImbalanceRegression](https://github.com/paobranco/Pre-processingApproachesImbalanceRegression) |
| **Language** | R |

## Replication Status: 🟡 In Progress

---

## Objective & Executive Summary

The objective of this replication is to independently verify the experimental results presented by Branco et al. regarding the use of re-sampling techniques (Under-sampling, Over-sampling, SMOTE, Gaussian Noise, and Importance Sampling) for tackling imbalanced regression problems.

The codebase executes a massive parallelized grid search evaluating 5 regression algorithms across 15 imbalanced tabular datasets. The goal is to reproduce the predictive performance scores (F-measure, Precision, Recall) under these pre-processing conditions.

---

## Architecture & Code Structure

The repository executes through a series of model-specific entry scripts, heavily relying on the `performanceEstimation` and `UBL` packages.

### Component Overview
1. **Model Entry Points**:
   - `expsIS_LM.R`: Linear Regression
   - `expsIS_RF.R`: Random Forest
   - `expsIS_SVM.R`: Support Vector Machines
   - `expsIS_NNET.R`: Neural Networks
   - `expsIS_MARS.R`: Multivariate Adaptive Regression Splines
2. **Core Pipeline (`AuxsIS.R`)**: Acts as the central integration layer. It defines workflow wrappers (`WFnone`, `WFRU`, `WFRO`, `WFGN`, `WFsmote`, `WFIS`) that intercept the data, apply the respective pre-processing strategy, and pass it to the prediction model.
3. **Data Source**: `DataSets15.Rdata` encapsulates the 15 standard regression datasets.

---

## Environment Setup

The execution environment is encapsulated via Conda (macOS arm64). Legacy R dependencies required patching due to missing architectural support and deprecated packages.

```bash
cd experiments/004_preprocessing_imbalanced_regression/
micromamba activate exp004
```

### Deviations & Technical Adaptations

1. **UBL Geospatial Dependency Stripping**: The original `UBL` package fails to compile on modern macOS arm64 due to heavy, obsolete C++ geospatial dependencies (`sf`, `gstat`, `automap`). Since this paper evaluates purely tabular data, these dependencies were ripped out of a cloned `UBL` source via `patch_all.R`, enabling a seamless local installation.
2. **Function Renaming**: The legacy function `ImpSampRegress` in `UBL` was deprecated and renamed to `WERCSRegress`. The global `AuxsIS.R` file was modified to redirect calls to the modern API.
3. **Typo Correction**: A syntax error (an unbalanced parenthesis in `PCSall[[11]])`) in the original Random Forest, SVM, and NNET scripts was stripped to allow execution.
4. **Thermal Optimization**: The `registerDoParallel(cores=7)` directive in the original scripts aggressively overwhelmed Apple Silicon CPUs (triggering thermal throttling at 99°C). The allocation was capped at `cores=4` for sustainable long-running experiments.

---

## How to Run

1. Ensure the `exp004` conda environment is active.
2. Execute the model runner scripts natively. Due to heavy processing, it is recommended to run them wrapped in `caffeinate` to prevent system sleep on macOS.

```bash
# Example: Running the Random Forest evaluations
caffeinate -dimsu -w $$ &
Rscript src/adapted/expsIS_RF.R
```

Outputs (`.Rdata` grids containing `ubaF`, `ubaprec`, and `ubarec`) are automatically generated inside `src/adapted/results/[MODEL_NAME]/`.
