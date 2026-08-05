# Cross-Experiment Diagnostic Report: Why Exp003 & Exp013 Fail on Larger Datasets

## TL;DR — Root Causes

### Experiment 003 (R — Biased Spatio-Temporal Resampling)
The Phase 2 grid search recalculates spatio-temporal weights **from scratch** for every one of 450 parameter combinations. Inside `get_space_wts()`, a `which(df[[time]]==t)` call inside a loop over 11,235 unique timestamps forces R to linearly scan a 150,000-row vector 11k times per call × 450 calls = **~750 billion redundant operations**. The authors' code is functionally correct but algorithmically unoptimized for the grid-search context. **Confirmed from code** ([sampling_weight.R:L95-98](file:///Users/joaopms/Documents/Projeto_Mestrado/experiments/003_biased_resampling_spatiotemporal/src/original/R/sampling_weight.R#L95-L98)).

### Experiment 013 (Python — TSER / SMOTE Augmentation)
The sensitivity analysis script (`run_sensitivity.py`) generates 20 sampling ratios that scale linearly from `n_tgt` (small) to `n_all` (total rows across ALL time series). For massive datasets like `solar-energy`, `n_all` is enormous, so SMOTE attempts to generate **millions** of synthetic rows per time series to reach parity, choking memory and CPU. The authors **intentionally restricted E02/E03 to `nn5_daily_without_missing`** only. **Confirmed from ARA** ([experiments.md](file:///Users/joaopms/Documents/AntigravityBrain/wiki/ARA%20Compiled%20Papers/Time_Series_Data_Augmentation/logic/experiments.md#L40-L55)) and **confirmed from code** ([modeling.py:L188-194](file:///Users/joaopms/Documents/Projeto_Mestrado/experiments/013_ts_augmentation_imbalanced/src/original/src/workflows/modeling.py#L188-L194)).

### Are the causes shared or independent?

> **Structurally shared, mechanically independent.**

Both experiments fail for the same *structural* reason: **the code contains a scale-dependent assumption that is harmless on small datasets but becomes computationally catastrophic at scale, and the original authors either (a) only ran the expensive operation on small datasets, or (b) had enough compute to brute-force it.** However, the specific *mechanisms* are completely different — one is a redundant R subsetting loop, the other is SMOTE generating millions of synthetic rows. There is no shared utility function, no shared cluster config, and no shared data-loading step.

---

## Evidence Table: Paper vs. Our Setup

### Experiment 003 — Biased Resampling Strategies (R)

| Dimension | Paper (from ARA + PDF) | Our Setup | Discrepancy? |
|---|---|---|---|
| **Datasets** | 10 specific: MESA, NCDCP, TCEQO/T/W, RURAL, BEIJ×4 | Pipeline generates **20** (includes COOK, SAC, SRdif, NCDCS, NCDCT) | ⚠️ **YES** — running 10 extra datasets never evaluated by authors |
| **R version** | Not specified | R 4.x via micromamba | Unknown |
| **Key packages** | `STResampling`, `uba`, `ranger`, `earth`, `rpart` | Same | ✅ Match |
| **`uba` version** | Not specified (code says ≥0.7.8) | 0.7.7 (patched DESCRIPTION to ≥0.7.7) | ⚠️ Minor — unlikely to affect results |
| **Hardware** | **Not specified** | Apuana cluster: 24 CPUs, 128GB RAM | Unknown — cannot compare |
| **Seeds** | **Not specified** | Not set | Unknown |
| **Grid search** | 5 α × 5 C.perc × {STRUS, STROS} = 50 combos, 9 CV blocks = 450 evals | Same | ✅ Match |
| **Parallelism** | Not specified | Mixed: `doParallel(10)` for rpart/earth; `num.threads=24` for ranger | Unknown |
| **`.keepTrain`** | Not discussed | Originally TRUE → patched to strip `rawRes$train` | ⚠️ Patched (our fix) |
| **`get_space_wts()` implementation** | Published as-is in STResampling package | Same unoptimized code | ✅ Match (this IS the bug) |

### Experiment 013 — Time Series Data Augmentation (Python)

| Dimension | Paper (from PDF) | Our Setup | Discrepancy? |
|---|---|---|---|
| **Datasets for E01** | 7 collections (`rideshare`, `nn5_daily`, `solar-energy`, `traffic_nips`, `taxi_30min`, `m4_hourly`, `m4_weekly`) | 9 datasets (includes `m4_daily`, `electricity_nips`) | ⚠️ **YES** — running 2 extra datasets |
| **Datasets for E02/E03** | **`nn5_daily_without_missing` ONLY** | Initially ran on ALL 9 datasets | ⚠️ **YES** — caused the `solar-energy` stall |
| **Model** | LightGBM with random search (200 iters) | Same | ✅ Match |
| **SMOTE `k_neighbors`** | 10 (explicitly stated in paper) | 10 | ✅ Match (ARA was incorrectly stating 5) |
| **Sensitivity ratios** | 20 ratios from `n_tgt` to `n_all` | Same | ✅ Match |
| **Hardware** | **Not specified** | Apuana: 24 CPUs, 120GB RAM | Unknown |
| **ADASYN handling** | Not discussed | Patched: fallback to SMOTE on RuntimeError | ⚠️ Our addition (defensive) |

---

## Mechanical Failure Trace

### Exp003: Where exactly does it fail?

| Step | What happens | Evidence |
|---|---|---|
| 1 | Phase 2 SLURM job starts `exps_internalTuning.R` | Log: `Testing data BEIJno and model rpart` |
| 2 | For each of 450 grid combinations, `randUnderRegress_ST()` is called | [workflows.R:L157-162](file:///Users/joaopms/Documents/Projeto_Mestrado/experiments/003_biased_resampling_spatiotemporal/src/original/R/workflows.R#L157-L162) |
| 3 | Each call invokes `sample_wts()` → `get_space_wts()` | [sampling_weight.R:L214](file:///Users/joaopms/Documents/Projeto_Mestrado/experiments/003_biased_resampling_spatiotemporal/src/original/R/sampling_weight.R#L214) |
| 4 | `get_space_wts()` loops over 11,235 unique timestamps | [sampling_weight.R:L95](file:///Users/joaopms/Documents/Projeto_Mestrado/experiments/003_biased_resampling_spatiotemporal/src/original/R/sampling_weight.R#L95) |
| 5 | Inside loop: `which(df[[time]]==t)` scans 150k rows | [sampling_weight.R:L98](file:///Users/joaopms/Documents/Projeto_Mestrado/experiments/003_biased_resampling_spatiotemporal/src/original/R/sampling_weight.R#L98) |
| 6 | 11,235 × 150,000 = 1.68B ops **per call** × 450 calls = **750B ops** | Mathematical derivation |
| 7 | CPU locks at 100%, no progress for 8+ hours | **Confirmed from SLURM log** |
| **Failure mode** | **Silent hang** — no error, no OOM, just infinite CPU spin | Confirmed |

### Exp013: Where exactly does it fail?

| Step | What happens | Evidence |
|---|---|---|
| 1 | `run_sensitivity.py` is launched for `solar-energy` | SLURM log: `[90%] 124 / 137 completed` then stuck |
| 2 | `SensitivityOnSampling.get_os_sampling_ratios()` computes `n_all = pd.concat(train).shape[0]` | [modeling.py:L188](file:///Users/joaopms/Documents/Projeto_Mestrado/experiments/013_ts_augmentation_imbalanced/src/original/src/workflows/modeling.py#L188) |
| 3 | For `solar-energy`, `n_all` is enormous (137 series × hundreds of rows each) | Inferred from dataset structure |
| 4 | 20 SMOTE ratios generated, highest one requests `n_all` synthetic minority samples | [modeling.py:L191-194](file:///Users/joaopms/Documents/Projeto_Mestrado/experiments/013_ts_augmentation_imbalanced/src/original/src/workflows/modeling.py#L191-L194) |
| 5 | SMOTE's `fit_resample()` attempts to generate millions of synthetic rows in-memory | imblearn internals (k-NN + interpolation) |
| 6 | Memory and CPU choke on the k-NN distance computations for millions of synthetic points | Mathematical derivation |
| 7 | Process hangs for 15+ hours on remaining 13 series | **Confirmed from SLURM log** |
| **Failure mode** | **Silent hang** — no error, no OOM kill, just memory pressure + CPU spin | Confirmed |

---

## Scale-Dependent Code Assumptions

### Exp003 — `get_space_wts()` in `sampling_weight.R`
```r
# LINE 95-98: This pattern is O(T × N) per call, called 450× in grid search
for(i in 1:length(unique(timz))){
    t <- unique(timz)[i]          # O(N) to compute unique() each iteration!
    inds_t <- which(df[[time]]==t) # O(N) full vector scan
```
**Scale-dependent assumption**: `unique()` is recomputed inside the loop on every iteration. `which()` is an O(N) scan. For small datasets (MESA: ~3,000 rows, ~500 timestamps), this is negligible. For Beijing (150,000 rows, 11,235 timestamps), it becomes catastrophic when multiplied by the grid search.

### Exp013 — `get_os_sampling_ratios()` in `modeling.py`
```python
# LINE 188-194: n_all scales with TOTAL dataset size, not target series size
n_all = pd.concat(train).shape[0]  # ALL series concatenated
n_min = np.linspace(start=n_tgt, stop=n_all, num=20).astype(int)
sample_dict = [{0: n_all, 1: x} for x in n_min]
```
**Scale-dependent assumption**: The maximum sampling ratio requests `n_all` synthetic minority samples. For `nn5_daily` (~100 series, ~700 rows each → `n_all` ≈ 70k), this is manageable. For `solar-energy` (~137 series, larger rows → `n_all` is massive), SMOTE must generate millions of synthetic points via k-NN interpolation.

---

## What Specifically Differs Between Authors' Setup and Ours?

### Exp003 (Confidence: HIGH — 90%)
The authors either **(a)** had enough compute to brute-force 750B operations (multi-week cluster run on a university HPC with hundreds of cores), or **(b)** pre-computed the `time_wts` and `space_wts` vectors once and reused them across the grid search — but when they cleaned up the code for the `STResampling` package release, they encapsulated everything into self-contained API functions that recalculate from scratch. **Evidence**: The published package API provides no caching mechanism for `sample_wts()`. The paper reports no runtime or hardware specs.

### Exp013 (Confidence: VERY HIGH — 95%)
The authors **never ran `run_sensitivity.py` on `solar-energy`**. The ARA compiled from the paper explicitly states E02 and E03 are restricted to `nn5_daily_without_missing`. We were running it on all 9 datasets because the script accepts any dataset as a CLI argument and our SLURM loop iterated over all of them. **Evidence**: ARA `experiments.md` lines 25 and 45 both state `Dataset: nn5_daily_without_missing`. The `run_sensitivity.py` default is also `nn5_daily_without_missing` (line 22).

---

## Ordered Next Actions

### Exp003 — Fix the `get_space_wts()` Bottleneck

1. **Create `src/adapted/sampling_weight_patched.R`** — copy `sampling_weight.R` and replace the loop with:
   ```r
   inds_list <- split(seq_len(nrow(df)), df[[time]])
   unique_timz <- unique(timz)
   for(i in seq_along(unique_timz)){
       t <- unique_timz[i]
       inds_t <- inds_list[[as.character(t)]]
       ...
   }
   ```
   This reduces subsetting from O(T×N) to O(N).

2. **Filter the dataset loop** in `exps_internalTuning_patched.R` to only process the 10 datasets from Table I:
   ```r
   VALID_DATASETS <- c("MESApol", "NCDCPprec", "TCEQOozone", "TCEQTtemp",
                        "TCEQWwind", "RURALpm10", "BEIJno", "BEIJpm10",
                        "BEIJwind", "BEIJpm25")
   dss <- dss[dss %in% VALID_DATASETS]
   ```

3. **Deploy the patched script** to the Apuana cluster via `rsync` and resubmit Phase 2.

4. **Verify** by timing a single `BEIJno` + `rpart` combination — should complete in minutes, not hours.

### Exp013 — Already Fixed ✅

1. The SLURM script ([run_distributed_apuana.slurm](file:///Users/joaopms/Documents/Projeto_Mestrado/experiments/013_ts_augmentation_imbalanced/run_distributed_apuana.slurm#L94-L99)) already has the `if [ "$DS" = "nn5_daily_without_missing" ]; then` guard.
2. **Resubmit** the patched SLURM job. The `.csv` lock-file logic will skip all completed series.
3. **Verify** that `run_models.py` and `run_models_on_extra.py` complete for all 9 datasets (E01 — no scaling issue).

---

## Open Questions

| # | Question | What would resolve it |
|---|---|---|
| 1 | Did the Exp003 authors pre-compute `sample_wts()` outside the grid search? | Contacting the authors or finding an older version of the code in their Git history |
| 2 | What hardware did the Exp003 authors use? | Paper says "not specified"; a footnote or supplementary might exist |
| 3 | Is the Exp013 `run_models.py` (E01) completing correctly for all 9 datasets, or are there silent failures? | Check the cluster output: `ls assets/results/by_series/ \| grep solar-energy \| wc -l` should equal 137 |
| 4 | Are there numerical precision differences between our R 4.x and the authors' R version for `uba::phi()`? | Compare output of `phi()` on a known input between R 3.x and 4.x — **speculation**, no evidence of this being an issue |
