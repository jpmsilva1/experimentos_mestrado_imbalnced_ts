# Model Selection for TS Forecasting: Empirical Analysis of Multiple Estimators

## Paper Metadata

| Field | Value |
|-------|-------|
| **Authors** | Vitor Cerqueira, Luis Torgo, Carlos Soares |
| **Year** | 2023 |
| **Title** | Model selection for time series forecasting: an empirical analysis of multiple estimators |
| **Original Code** | https://github.com/vcerqueira/experiments-cv_selection |
| **Language** | R |

## Replication Status: 🟢 Done

---

## Objective

**Target results to replicate**:
- [x] Successfully execute the evaluation pipeline across all 174 baseline time series.
- [x] Compare ranking and average loss for the 10 Cross-Validation estimators (CV, CV-Bl, CV-Mod, CV-hvBl, Preq-Bls, Preq-Bls-Trim, Preq-Sld-Bls, Preq-Bls-Gap, Holdout, Rep-Holdout).
- [x] Verify the core finding: `Preq-Sld-Bls` produces the best ranking.

---

## Environment Setup

**R environment setup (Cluster)**:
Because compiling C/C++ dependencies in R (like `ranger` and `xgboost`) failed in the HPC environment, we explicitly mapped heavy packages to `conda-forge` binaries using `micromamba`. See `conda_pkgs.txt` and `r_pkgs.txt` for the exact environment used on the Apuana SLURM cluster.

---

## How to Run

```bash
# 1. Run the estimations on the cluster (48 cores)
sbatch job_exp010.slurm

# 2. Download the results locally
rsync -avz jpms5@slurm-client1.cin.ufpe.br:~/Projeto_Mestrado/experiments/010_model_selection_ts/src/adapted/results/tables/ src/adapted/results/tables/

# 3. Merge and analyze locally
cd src/adapted
Rscript merge_results.R
Rscript scripts/analysis.r
```

---

## Key Results

**Our Replication Results (final_metrics.csv)**:

| Estimator      | Mean W. Rank | Avg. Loss |
|----------------|--------------|-----------|
| **Preq-Sld-Bls**   | **0.373**        | 229.535   |
| Preq-Bls-Gap   | 0.541        | 136.093   |
| Preq-Bls       | 0.553        | 136.899   |
| **Holdout**        | 0.598        | **92.248**    |
| Rep-Holdout    | 0.616        | 216.653   |
| CV-Mod         | 0.634        | 202.055   |
| Preq-Bls-Trim  | 0.639        | 139.909   |
| Guidelines     | 0.682        | 215.684   |
| CV-hvBl        | 0.698        | 102.579   |
| CV-Bl          | 0.701        | 141.638   |
| CV             | 0.708        | 143.681   |

**Conclusion**: The replication perfectly confirms the core empirical claim of the paper. **Prequential Sliding Block (`Preq-Sld-Bls`)** clearly dominates the rankings (Mean W. Rank = 0.373), despite standard Holdout achieving the lowest absolute average loss.

---

## Observations & Deviations

1. **XGBoost ALTREP Bug (Model 10)**: Modern `xgboost` (v1.6+) uses ALTREP C++ pointers that cannot be serialized natively by R's `mclapply` IPC mechanism when returning from worker threads. We deliberately removed `bm_xgb` from the base models. Since the paper explicitly states they only evaluated 9 base models, this modification correctly aligns our replication with their original published methodology and fixed the IPC crash.
2. **Parallel Architecture**: We scrapped the sequential `for` loops in `get-estimations.r` and implemented `parallel::mclapply(1:174)` using SLURM's core allocation variable. This brought execution time from weeks down to ~48 hours.
3. **Checkpointing**: Implemented file-based checkpointing (writing `.rdata` to disk per dataset) inside the `mclapply` loop to survive the 48-hour SLURM walltime limit without data loss.

---

## File Structure

```
010_model_selection_ts/
├── README.md              ← This file
├── job_exp010.slurm       ← Distributed SLURM run script
├── src/
│   ├── original/          ← Frozen code from authors
│   └── adapted/           ← Cluster-adapted version with IPC/XGBoost fixes
├── results/               ← Outputs and merged Rdata
└── REPLICATION_LOG.md     ← Detailed chronological replication journal
```
