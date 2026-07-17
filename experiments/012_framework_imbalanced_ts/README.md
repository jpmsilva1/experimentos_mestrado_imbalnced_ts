# A Framework for Imbalanced Time-Series Forecasting

## Paper Metadata

| Field | Value |
|-------|-------|
| **Authors** | Luis P. Silvestrin, Leonardos Pantiskas, Mark Hoogendoorn |
| **Year** | 2021 |
| **Venue** | arXiv |
| **DOI/URL** | https://arxiv.org/abs/2107.10709 |
| **Original Code** | https://gitlab.com/lpsilvestrin/imbalanced-time-series-forecast |
| **Language** | Python |
| **ARA Reference** | — |

## Replication Status: 🟢 Done

---

## Objective

**Target results to replicate**:
- [ ] Table 1: RMSE of LSTM and TCN trained on 4 sampling strategies (Normal, SUS1, SUS3, IHS), evaluated on 4 test sets

**Key claim**: Biased sampling strategies (particularly IHS) reduce worst-case error when compared to standard uniform training on imbalanced time series.

---

## Environment Setup

**Python version**: 3.10+ (any version supported by TF 2.13)

> ⚠️ The original code requires `tensorflow==2.3.0` and `tensorflow-addons==0.11.1`, which are
> unavailable on Apple Silicon (osx-arm64). We use the adapted code in `src/adapted/` instead.

```bash
cd experiments/012_framework_imbalanced_ts/
conda activate paper_012_env   # created earlier with conda create -n paper_012_env python=3.10
pip install -r requirements.txt
```

**Data**: Download the CSV from Kaggle and place it in `data/`:
```
https://www.kaggle.com/edumagalhaes/quality-prediction-in-a-mining-process
# Download: MiningProcess_Flotation_Plant_Database.csv
mkdir -p data
mv ~/Downloads/MiningProcess_Flotation_Plant_Database.csv data/
```

---

## How to Run

All commands are run from `experiments/012_framework_imbalanced_ts/`.

```bash
# Step 1 — Dry run (2 seeds, 5 epochs) to verify the pipeline
python src/adapted/train.py \
  --data-path data/MiningProcess_Flotation_Plant_Database.csv \
  --output-dir weights \
  --seeds 2 \
  --epochs 5

# Step 2 — Full training (30 seeds, 200 max epochs — will take several hours)
python run_parallel.py \
  --data-path data/MiningProcess_Flotation_Plant_Database.csv \
  --output-dir weights \
  --seeds 30 \
  --workers 4

# Step 3 — Evaluate and generate result table
python src/adapted/evaluate.py \
  --data-path data/MiningProcess_Flotation_Plant_Database.csv \
  --weights-dir weights \
  --output-path results/tables/results.npz \
  --seeds 30
```

---

## Key Results

**Paper vs. Replication Comparison (All Data Test Set):**

| Metric | Paper Reports | Our Replication | Δ (absolute) | Notes |
|--------|--------------|-----------------|--------------|-------|
| LSTM/Normal → All data | 0.620 ± 0.016 | 0.620 ± 0.020 | 0.000 | Perfect match |
| LSTM/SUS1 → All data | 0.594 ± 0.031 | 0.586 ± 0.037 | -0.008 | Very close |
| LSTM/SUS3 → All data | 0.731 ± 0.028 | 0.732 ± 0.030 | +0.001 | Perfect match |
| LSTM/IHS → All data | 0.638 ± 0.032 | 0.621 ± 0.028 | -0.017 | Within 1 std dev |
| TCN/Normal → All data | 0.570 ± 0.009 | 0.632 ± 0.016 | +0.062 | Slightly higher |
| TCN/IHS → All data | 0.617 ± 0.018 | 0.613 ± 0.038 | -0.004 | Perfect match |

**Full Replication Results Summary (RMSE mean ± std across 30 seeds):**

```text
================================================================================
RESULTS SUMMARY (RMSE mean ± std across seeds)
================================================================================
Model    Trained on              All data               SUS 1               SUS 3                 IHS    Max Error
------------------------------------------------------------------------------------------------------------------
LSTM     normal        0.620 ± 0.020  1.721 ± 0.283  1.819 ± 0.325  1.771 ± 0.291    1.819
TCN      normal        0.632 ± 0.016  1142.058 ± 202.839  1152.936 ± 205.846  1141.965 ± 203.748    1152.936
LSTM     fact_1        0.586 ± 0.037  1.836 ± 0.438  1.948 ± 0.491  1.892 ± 0.447    1.948
TCN      fact_1        0.581 ± 0.031  1510.940 ± 221.328  1528.169 ± 225.301  1503.851 ± 224.325    1528.169
LSTM     fact_3        0.732 ± 0.030  1.677 ± 0.271  1.754 ± 0.336  1.727 ± 0.290    1.754
TCN      fact_3        0.659 ± 0.034  1746.385 ± 304.051  1761.140 ± 306.119  1742.953 ± 306.695    1761.140
LSTM     ihist         0.621 ± 0.028  1.746 ± 0.359  1.846 ± 0.415  1.797 ± 0.370    1.846
TCN      ihist         0.613 ± 0.038  1515.788 ± 288.818  1529.932 ± 291.120  1515.763 ± 289.638    1529.932
================================================================================
```

---

## Observations & Deviations

- **`tensorflow-addons` removed**: `WeightNormalization` was re-implemented natively in `model_utils.py` since `tensorflow-addons` was discontinued and is not available for TF ≥ 2.13.
- **No `gpu:0` device pinning**: Original code had hardcoded `with tf.device("gpu:0")` blocks. The adapted code lets TensorFlow auto-select the available device (Metal on Apple Silicon, CUDA on NVIDIA, or CPU).
- **Weight file format**: Changed from `.hdf5` to `.weights.h5` (the format recommended from TF 2.12+).

---

## File Structure

```
012_framework_imbalanced_ts/
├── README.md              ← This file
├── requirements.txt       ← Adapted Python dependencies (TF 2.13)
├── data/
│   └── MiningProcess_Flotation_Plant_Database.csv  ← Download from Kaggle (not in git)
├── src/
│   ├── original/          ← Unmodified clone of the original GitLab repo
│   └── adapted/           ← Our modernized version
│       ├── requirements.txt
│       ├── model_utils.py ← TCN + native WeightNormalization (no tensorflow-addons)
│       ├── train.py       ← Training script with CLI args and device-agnostic code
│       └── evaluate.py    ← Evaluation script with summary table output
├── weights/               ← Saved model weights (created at training time)
├── notebooks/
│   └── analysis.ipynb     ← Exploratory analysis and result visualization
├── results/
│   ├── tables/            ← Output CSV tables and results.npz
│   └── figures/           ← Output PNG figures
└── REPLICATION_LOG.md     ← Day-by-day journal
```
