# Replication Methodology

This document describes the systematic methodology used for replicating experiments from the literature.

---

## Definition of "Replication"

In this repository, **replication** means:

1. **Obtaining** the original source code from the paper's public repository (**done manually by the user** — copied into `src/original/`)
2. **Setting up** the environment (dependencies, data, configuration)
3. **Running** the original code with the original parameters
4. **Comparing** our output with the results reported in the paper
5. **Documenting** any deviations, issues, or insights

We are **NOT** reimplementing from scratch. We are verifying that the original code produces the claimed results.

> **Note**: All code, dataset, and file insertion is a **manual process** performed by the researcher. The repository scaffolding provides the structure and conventions; the user populates each experiment folder at their own pace.

---

## Replication Criteria

An experiment is considered **successfully replicated** when:

- The original code runs without errors in our environment
- Key metrics (RMSE, MAE, F1, SERA, etc.) match the paper within a **reasonable tolerance** (±5% for stochastic methods, exact match for deterministic)
- Any deviations are explained (different random seeds, library versions, data splits)

---

## Standard Workflow per Experiment

1. **Read the paper** — understand the claims, methodology, and target results
2. **Read the ARA** (if exists) — review compiled knowledge in the Obsidian Vault
3. **Insert the code** — manually copy/clone the original code into `src/original/` (user-owned step)
4. **Insert datasets** — manually place required data files locally (user-owned step)
5. **Set up environment** — create isolated `venv` or `conda` env
6. **Run original code** — with original parameters, document the process
7. **Record results** — save outputs to `results/`, fill comparison table
8. **Document** — complete README and REPLICATION_LOG
9. **Update dashboard** — run `scripts/update_readme.py`

---

## Evaluation Metrics Reference

| Metric | Domain | Description |
|--------|--------|-------------|
| RMSE | Regression | Root Mean Squared Error |
| MAE | Regression | Mean Absolute Error |
| SERA | Imbalanced Regression | Squared Error-Relevance Area (from IRon) |
| F1 | Classification | Harmonic mean of precision and recall |
| AUC-ROC | Classification | Area under ROC curve |
| TSS | Classification | True Skill Statistic (used in solar flare prediction) |

---

## Tools & Infrastructure

- **Python**: Primary language (most experiments)
- **R**: Secondary language (UBA, IRon, some Torgo group papers)
- **Git**: Version control for all code and results
- **Obsidian Vault**: Cross-referenced knowledge base (ARAs)
- **W&B / MLflow**: Optional experiment tracking for complex runs
