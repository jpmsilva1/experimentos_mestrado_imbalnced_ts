# Model Selection for TS Forecasting: Empirical Analysis of Multiple Estimators

## Paper Metadata

| Field | Value |
|-------|-------|
| **Authors** | [AUTHORS] |
| **Year** | [YEAR] |
| **Venue** | [VENUE] |
| **DOI/URL** | [DOI_URL] |
| **Original Code** | https://github.com/vcerqueira/experiments-cv_selection |
| **Language** | [Python/R/Both] |
| **ARA Reference** | [Link to ARA in Obsidian Vault, if exists] |
| **Excel Row** | [Row number in Fichamento_Artigos.xlsx] |

## Replication Status: ⚪ Pending

<!-- Update this to: 🔵 Setup | 🟡 In Progress | 🟢 Done | 🔴 Blocked -->

---

## Objective

<!-- Specify exactly which results from the paper you are replicating -->
**Target results to replicate**:
- [ ] Table X: [description]
- [ ] Figure Y: [description]
- [ ] Key claim: [description]

---

## Environment Setup

**Python version**: X.Y.Z

```bash
cd experiments/010_model_selection_ts/
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

**Additional setup steps**:
<!-- Document any non-trivial setup (data downloads, config changes, etc.) -->

---

## How to Run

```bash
# Step 1: [description]
# Step 2: [description]
```

---

## Key Results

| Metric | Paper Reports | Our Replication | Δ (absolute) | Notes |
|--------|--------------|-----------------|--------------|-------|
| | | | | |

---

## Observations & Deviations

<!-- Document any differences between your replication and the original paper:
- Different library versions
- Missing data
- Adjusted hyperparameters
- Results that don't match
-->

---

## File Structure

```
010_model_selection_ts/
├── README.md              ← This file
├── requirements.txt       ← Python dependencies
├── config/
│   └── default.yaml       ← Experiment configuration
├── src/
│   ├── original/          ← Original code (unmodified snapshot or submodule)
│   └── adapted/           ← Your modifications (if any)
├── notebooks/
│   └── analysis.ipynb     ← Exploratory analysis and result visualization
├── results/
│   ├── tables/            ← Output CSV tables
│   └── figures/           ← Output PNG figures
└── REPLICATION_LOG.md     ← Day-by-day journal
```
