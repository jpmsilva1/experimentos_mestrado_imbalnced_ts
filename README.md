# 📊 Imbalanced Time Series — Experiment Replication Repository

---

## 📈 Progress Summary

| Status | Count |
|--------|-------|
| 🟢 Done | 3 |
| 🟡 In Progress | 2 |
| 🔵 Setup | 0 |
| ⚪ Pending | 12 |
| 🔴 Blocked | 0 |
| **Total** | **17** |

**Last updated**: 2026-07-17

---

## 🗂️ Experiment Index

| # | Paper | Year | Authors | Status | Original Code | Folder |
|---|-------|------|---------|--------|---------------|--------|
| 001 | Utility-based Regression | 2007 | Ribeiro, Torgo | ⚪ Pending | [GitHub](https://github.com/rpribeiro/uba) | [→](experiments/001_uba_utility_regression/) |
| 002 | Resampling Strategies for Imbalanced Time Series Forecasting | 2017 | Moniz, Branco, Torgo | 🟢 Done | [GitHub](https://github.com/nunompmoniz/TSResampStrat_JDSA2017) | [→](experiments/002_ts_resampling_strategies/) |
| 003 | Biased Resampling Strategies for Imbalanced Spatio-Temporal Forecasting | 2019 | Oliveira, Torgo, Santos Costa | 🟡 In Progress | [GitHub](https://github.com/mrfoliveira/STResampling-DSAA2019) | [→](experiments/003_biased_resampling_spatiotemporal/) |
| 004 | Pre-processing Approaches for Imbalanced Distributions in Regression | 2019 | Branco, Torgo, Ribeiro | ⚪ Pending | [GitHub](https://github.com/paobranco/Pre-processingApproachesImbalanceRegression) | [→](experiments/004_preprocessing_imbalanced_regression/) |
| 005 | Imbalanced Regression and Extreme Value Prediction (IRon/SERA) | 2020 | Moniz, Ribeiro, Cerqueira, Chawla | ⚪ Pending | [GitHub](https://github.com/nunompmoniz/IRon/tree/master) | [→](experiments/005_iron_sera_extreme_value/) |
| 006 | Evaluating Time Series Forecasting Models: Performance Estimation | 2020 | Cerqueira, Torgo, Mozetič | ⚪ Pending | [GitHub](https://github.com/vcerqueira/experiments-performance_estimation) | [→](experiments/006_performance_estimation_ts/) |
| 007 | A Case Study Comparing ML with Statistical Methods for TS Forecasting | 2022 | Cerqueira, Torgo, Soares | ⚪ Pending | [GitHub](https://github.com/vcerqueira/experiments-sizematters) | [→](experiments/007_ml_vs_statistical_ts/) |
| 008 | Gaussian Processes for Hierarchical Time Series Forecasting | 2022 | Roque, Torgo, Soares | ⚪ Pending | [GitHub](https://github.com/luisroque/hierarchical_gp_forecaster) | [→](experiments/008_gp_hierarchical_ts/) |
| 009 | Minority Oversampling for Imbalanced Time Series Classification (OHIT) | 2022 | Zhu, Luo, Zhang, Li, Ren, Zeng | ⚪ Pending | [GitHub](https://github.com/zhutuanfei/OHIT) | [→](experiments/009_ohit_minority_oversampling/) |
| 010 | Model Selection for TS Forecasting: Empirical Analysis | 2023 | Cerqueira, Torgo, Soares | ⚪ Pending | [GitHub](https://github.com/vcerqueira/experiments-cv_selection) | [→](experiments/010_model_selection_ts/) |
| 011 | Early Anomaly Detection: Hierarchical Approach for Critical Health Episodes | 2023 | Cerqueira, Torgo, Soares | ⚪ Pending | [GitHub](https://github.com/vcerqueira/experiments-layered_learning) | [→](experiments/011_early_anomaly_hierarchical/) |
| 012 | A Framework for Imbalanced Time-Series Forecasting | 2023 | Silvestrin, Pantiskas, Brunton | 🟢 Done | [GitLab](https://gitlab.com/lpsilvestrin/imbalanced-time-series-forecast) | [→](experiments/012_framework_imbalanced_ts/) |
| 013 | Time Series Data Augmentation as an Imbalanced Learning Problem | 2024 | Cerqueira, Torgo | 🟡 In Progress | [GitHub](https://github.com/vcerqueira/experiments-tser) | [→](experiments/013_ts_augmentation_imbalanced/) |
| 014 | RHiOTS: Evaluating Hierarchical TS Forecasting Algorithms | 2024 | Roque, Soares, Torgo | ⚪ Pending | [GitHub](https://github.com/luisroque/robustness_hierarchical_time_series_forecasting_algorithms) | [→](experiments/014_rhiots_hierarchical/) |
| 015 | Resampling Strategies for Imbalanced Regression: Survey & Empirical Analysis | 2024 | Avelino et al. | 🟢 Done | [GitHub](https://github.com/JusciAvelino/imbalancedRegression) | [→](experiments/015_resampling_imbalanced_regression/) |
| 016 | Instance-Based Meta-Learning for Selecting Forecasting Models | 2024 | Cerqueira, Torgo, Bontempi | ⚪ Pending | [GitHub](https://github.com/vcerqueira/metaforecast) | [→](experiments/016_metaforecast_instance_based/) |
| 017 | Imbalanced Regression Pipeline Recommendation (PhD Thesis) | 2024 | Avelino, Juscimara | ⚪ Pending | — | [→](experiments/017_imbalanced_regression_pipeline/) |

---

## 🏷️ Status Legend

| Badge | Meaning | Criteria |
|-------|---------|----------|
| ⚪ Pending | Not started | Folder scaffolded but no work done |
| 🔵 Setup | Environment ready | Code cloned, dependencies installed, environment documented |
| 🟡 In Progress | Actively replicating | Running experiments, collecting results |
| 🟢 Done | Replication complete | Results reproduced, comparison table filled, README complete |
| 🔴 Blocked | Cannot proceed | Missing data, broken dependencies, or other blockers documented |

---

## 🔗 Related Resources

- **Literature Review Tracker**: `Fichamento_Artigos.xlsx` (Google Drive — 43 papers)
- **ARA Knowledge Base**: `/AntigravityBrain/wiki/ARA Compiled Papers/` (15 compiled ARAs)
- **Full Paper Registry**: [paper_registry.md](docs/paper_registry.md)
- **Replication Methodology**: [methodology.md](docs/methodology.md)
- **Contribution Rules**: [CONTRIBUTING.md](CONTRIBUTING.md)

---

## 🚀 Quick Start

```bash
# Create a new experiment from template
./scripts/new_experiment.sh 018 "my_new_experiment" "Paper Title" "https://github.com/author/repo"

# Regenerate this README's status table from experiment data
python3 scripts/update_readme.py

# Sync paper registry from Excel
python3 scripts/sync_from_excel.py
```

---

## 📋 Priority Guide

Experiments are numbered by priority. Work on them in order:

- **P0 (001–005)**: Core thesis papers — resampling strategies and evaluation metrics for imbalanced regression
- **P1 (006–011)**: Methodology papers — performance estimation, model selection, and anomaly detection from the Cerqueira/Torgo group
- **P2 (012–015)**: Extended scope — frameworks, augmentation, hierarchical forecasting
- **P3 (016–017)**: Reference implementations — meta-learning and pipeline recommendation

---

Guide Site: https://jpmsilva1.github.io/experimentos_mestrado_imbalnced_ts/
