# 1. The Big Picture: What Is This Repository?

This repository is a **private, structured research laboratory** for systematically replicating 17 academic papers on imbalanced time series forecasting and regression — the core empirical work of a Master's thesis at CIn–UFPE.

## 1.1 What "Replication" Means Here

You are **not** re-implementing papers from scratch. The workflow is:

1. Obtain the **original authors' source code** and place it inside the repository.
2. **Run that code** in a clean, isolated virtual environment.
3. **Compare your outputs** against the results reported in the paper.
4. **Document everything**: what matched, what differed, and why.

> Your role is that of a **scientific auditor** — not a reimplementer.

This distinction matters because it defines what work is automated and what is always manual.

---

## 1.2 The Automation Boundary

The repository's design explicitly separates bookkeeping (automated) from scientific judgment (always manual).

| Automated by scripts | Always done manually by you |
|---|---|
| Creating the experiment folder structure | Cloning or copying the original source code |
| Replacing placeholder text in template files | Downloading datasets |
| Rebuilding the progress dashboard in `README.md` | Running the experiments |
| Syncing paper metadata from the Excel spreadsheet | Interpreting results and filling the comparison table |
| Generating this guide as a PDF | Marking an experiment as Done |

The most important rule: **you control all data and code insertion**. Scripts only handle administrative bookkeeping.

---

## 1.3 Repository Goals

By the end of the thesis, this repository should contain:

- **17 fully replicated experiments**, each with a complete scientific report.
- **Documented deviations** from original paper results, with explanations.
- A **paper registry** of all 43 papers in the reading list, with replication status.
- **Shared utilities** for metrics and visualization that are reusable across experiments.

---

## 1.4 Reading This Guide

This guide is organized in the order you will need the information:

| Chapter | When you need it |
|---|---|
| 2 — Directory Structure | First session: orienting yourself |
| 3 — Experiment Lifecycle | Every experiment: knowing what stage you are in |
| 4 — Core Workflow | Every session: the exact step-by-step protocol |
| 5 — Automation Scripts | When running or understanding the scripts |
| 6 — File Reference | When filling in any experiment file |
| 7 — Environments | When setting up a new Python environment |
| 8 — Git Workflow | After each work session |
| 9 — Adding Experiments | When adding experiment #018 or beyond |
| 10 — Rules | Quick reference cheatsheet |
| 11 — Troubleshooting | When something breaks |
