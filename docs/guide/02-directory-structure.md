# 2. Directory Structure

This chapter is the canonical reference for the repository layout. Every top-level folder has a single, well-defined purpose. Understanding this structure is a prerequisite for all other work.

## 2.1 Full Layout

```text
experimentos_mestrado_imbalnced_ts/
│
├── README.md                     <- Master dashboard (auto-updated, never edit by hand)
├── CONTRIBUTING.md               <- The rules: how to add / maintain experiments
├── .gitignore                    <- What Git ignores: venvs, datasets, build artifacts
│
├── experiments/                  <- One subfolder per paper replication
│   │
│   ├── _template/                <- Blueprint. NEVER edit directly.
│   │   ├── README.md             <- Structured experiment report (fill this in)
│   │   ├── REPLICATION_LOG.md    <- Daily work diary (prepend new entries)
│   │   ├── requirements.txt      <- Python dependencies for this experiment
│   │   ├── config/
│   │   │   └── default.yaml      <- Key parameters: seeds, paths, hyperparams
│   │   ├── src/
│   │   │   ├── original/         <- AUTHORS' code goes here (manual, never scripted)
│   │   │   └── adapted/          <- YOUR changes and wrappers go here
│   │   ├── notebooks/            <- Exploratory Jupyter notebooks
│   │   └── results/
│   │       ├── tables/           <- CSV / XLSX output tables
│   │       └── figures/          <- Generated plots and visualizations
│   │
│   ├── 001_uba_utility_regression/
│   ├── 002_ts_resampling_strategies/
│   ├── ... (17 experiment folders in total)
│   └── 017_imbalanced_regression_pipeline/
│
├── scripts/                      <- Automation tools (bookkeeping only)
│   ├── new_experiment.sh         <- Scaffolds a new experiment from _template
│   ├── update_readme.py          <- Rebuilds the progress dashboard in README.md
│   └── sync_from_excel.py        <- Syncs paper metadata from Google Drive Excel
│
├── shared/                       <- Code reused across multiple experiments
│   ├── datasets/
│   │   └── README.md             <- Registry of shared datasets and download instructions
│   ├── metrics/
│   │   ├── regression.py         <- RMSE, MAE, SMAPE — fallback only; prefer paper's own
│   │   └── classification.py     <- F1, Precision, Recall — fallback only
│   ├── visualization/
│   │   └── plot_utils.py         <- Publication-quality matplotlib helpers
│   └── utils/
│       └── data_loading.py       <- Path helpers for navigating the repo structure
│
├── docs/                         <- Reference documents and this guide
│   ├── guide/                    <- Source for this PDF
│   ├── paper_registry.md         <- Auto-generated registry of all 43 papers
│   └── methodology.md            <- Scientific replication methodology
│
└── .github/
    └── ISSUE_TEMPLATE/
        └── new-experiment.md     <- GitHub issue template for proposing new experiments
```

---

## 2.2 Folder Reference

### `experiments/` — The Core of the Repository

This is where all research lives. Each subfolder corresponds to one paper replication and follows a strict naming convention:

```text
NNN_descriptive_name/
```

Where `NNN` is a zero-padded three-digit number that encodes the **priority order** of the experiment. Lower numbers are done first.

**Golden rules for `experiments/`:**

- Never add a folder by hand. Always use `new_experiment.sh`.
- Never rename an existing folder. The number is the experiment's permanent identifier.
- The folder structure inside each experiment must match `_template/` exactly.

---

### `experiments/_template/` — The Blueprint

This folder defines the schema for every experiment in the repository. The automation script `new_experiment.sh` copies it in its entirety when creating a new experiment.

> **Critical rule:** Never edit `_template/` to fix a single experiment. If you edit the template, you are changing the contract for all *future* experiments. Edit the specific experiment folder instead.

**Contents of each experiment folder:**

| File / Folder | Purpose | Who fills it |
|---|---|---|
| `README.md` | Structured scientific report: metadata, results, status | You |
| `REPLICATION_LOG.md` | Chronological work diary, newest entry on top | You |
| `requirements.txt` | Exact Python package versions (`pip freeze`) | You |
| `config/default.yaml` | Experiment parameters: seeds, paths, hyperparams | You |
| `src/original/` | Authors' original source code, cloned or copied | You (manual) |
| `src/adapted/` | Your modifications, wrappers, and analysis code | You |
| `notebooks/` | Jupyter notebooks for exploration | You |
| `results/tables/` | Output CSVs and comparison tables | Experiments |
| `results/figures/` | Generated plots | Experiments |

---

### `scripts/` — Automation Tools

These scripts handle **bookkeeping only**. They never touch your data or experiment results.

| Script | When to run | What it does |
|---|---|---|
| `new_experiment.sh` | Adding an experiment after #017 | Copies `_template/`, renames placeholders, sets date |
| `update_readme.py` | After changing any experiment's status | Rebuilds the status table in the root `README.md` |
| `sync_from_excel.py` | After updating the Google Drive paper spreadsheet | Regenerates `docs/paper_registry.md` |

---

### `shared/` — Cross-Experiment Code

Code that is genuinely reused across multiple experiments lives here instead of being duplicated inside each experiment folder.

**Important usage rule:** The `shared/metrics/` implementations are **fallback implementations** only. If the paper provides its own metric code, use that. Shared metrics exist to avoid duplication when no reference implementation is available.

---

### `docs/` — Documentation

The `docs/` folder contains reference material about the project as a whole, not about any individual experiment.

| File | Description |
|---|---|
| `guide/` | Source Markdown files for this PDF guide |
| `paper_registry.md` | Auto-generated list of all 43 papers from the Excel spreadsheet |
| `methodology.md` | The scientific replication methodology (what counts as a valid replication) |

---

## 2.3 The Two Critical Boundaries

These two rules are the most important structural decisions in the repository. Violating them breaks traceability.

**Boundary 1 — `_template/` is immutable per experiment.**
The script creates your experiment folder from the template. After that, only *you* edit the experiment folder. The template is never touched again for that experiment.

**Boundary 2 — `src/original/` is always filled manually.**
No script will ever write to `src/original/`. You clone or copy the authors' code there. This makes the provenance of all code 100% explicit and auditable.
