# Resampling Strategies for Imbalanced Time Series Forecasting

## Paper Metadata

| Field | Value |
|-------|-------|
| **Title** | Resampling Strategies for Imbalanced Time Series Forecasting |
| **Authors** | Nuno Moniz, Rita P. Ribeiro, Luís Torgo |
| **Year** | 2017 |
| **Venue** | International Journal of Data Science and Analytics (JDSA) |
| **DOI/URL** | https://doi.org/10.1007/s41060-017-0044-3 |
| **Original Code** | https://github.com/nunompmoniz/TSResampStrat_JDSA2017 |
| **Language** | R (performanceEstimation, uba, UBL) |
| **ARA Reference** | [TSResampStrat_JDSA2017] |

## Replication Status: 🟢 Done (20 Datasets Evaluated)

---

## Objective

**Target results to replicate**:
- [x] Evaluation of utility-based $F_1$ score metric across imbalanced time series forecasting tasks.
- [x] Paired Wilcoxon Signed-Rank statistical comparison of resampling methods (OVERT, OVERB, UNDERB, SMOTE) against un-resampled baseline models (`lm`, `svm`, `mars`, `rf`, `rpart`).
- [x] Verification of key paper claim: Resampling strategies consistently improve utility-based $F_1$ performance over standard forecasting models.

---

## Key Results (20 Datasets Evaluated)

| Rank | Workflow | Replicated Avg $F_1$ | Paper Finding Alignment | Notes |
|:---:|:---|:---:|:---|:---|
| 1 | `mc.lm_OVERT` | **0.5416** | ✅ Matches top rank | Random Oversampling with Threshold |
| 2 | `mc.lm_OVERTPhi` | **0.5406** | ✅ Matches top rank | Relevance-weighted Oversampling |
| 3 | `mc.lm_OVERB` | **0.5317** | ✅ High ranking | Random Oversampling |
| 4 | `mc.lm_UNDERB` | **0.5297** | ✅ High ranking | Random Undersampling |
| 5 | `mc.lm_UNDERT` | **0.5287** | ✅ High ranking | Undersampling with Threshold |
| 6 | `mc.svm_OVERT` | **0.5256** | ✅ High ranking | SVM + Oversampling with Threshold |
| 7 | `mc.svm_OVERTPhi` | **0.5256** | ✅ High ranking | SVM + Relevance Oversampling |

### Paired Comparison Matrix Summary (20 Datasets)
- **Resampled Workflows vs. Un-resampled Baselines**: Resampled workflows achieved **20 Wins / 0 Losses / 0 Ties** against plain un-resampled baselines (`mc.lm`, `mc.svm`, `mc.rpart`), confirming the paper's core hypothesis.

---

## Observations & Deviations

1. **Dataset Scope**: Results compiled across **20 completed datasets** (out of 24 original datasets). Datasets 21–24 (high-frequency half-hourly series with $N=17,500$ points) were skipped due to C-level `forecast::auto.arima` optimization hangs (>50h per fold).
2. **`auto.arima` Patch**: On high-frequency series, `mc.arima` was patched with `approximation=TRUE` and `stepwise=TRUE` to avoid infinite BFGS optimization loops inside R's C routine `stats:::C_arima`.
3. **Metric Storage**: Utility-based metrics (`prec`, `rec`, `F1`) are produced by the `uba` package and stored inside `obj@iterationsInfo[[i]]$evaluation` across Monte Carlo iterations.

---

## How to Run

```bash
# On SLURM Cluster:
cd ~/Projeto_Mestrado/experiments/002_ts_resampling_strategies
sbatch run_apuana.slurm

# Merge completed datasets:
Rscript src/adapted/merge_results.R

# Generate evaluation tables & Paired Comparisons:
Rscript src/adapted/PairedComparisons.R
```

---

## File Structure

```
002_ts_resampling_strategies/
├── README.md              ← This file
├── REPLICATION_LOG.md     ← Day-by-day replication log
├── run_apuana.slurm       ← SLURM execution script
├── src/
│   ├── original/          ← Original author code snapshot
│   └── adapted/           ← Adapted execution & evaluation scripts
│       ├── Exps.R
│       ├── merge_results.R
│       └── PairedComparisons.R
└── results/
    ├── merged_results.Rdata
    └── workflow_f1_rankings.csv
```
