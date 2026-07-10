## 2. Directory Structure: A Map of the Repository

```
experimentos_mestrado_imbalnced_ts/
│
├── README.md                     ← 🏠 The master dashboard. Auto-updated by scripts.
├── CONTRIBUTING.md               ← 📜 The law. Rules for adding/maintaining experiments.
├── .gitignore                    ← What Git ignores (data files, venvs, etc.)
│
├── experiments/                  ← 🧪 One subfolder per paper replication
│   ├── _template/                ← 📋 Blueprint. Never edit directly. Copied by script.
│   │   ├── README.md
│   │   ├── REPLICATION_LOG.md
│   │   ├── requirements.txt
│   │   ├── config/
│   │   │   └── default.yaml
│   │   ├── src/
│   │   │   ├── original/         ← YOU PUT CODE HERE (manually)
│   │   │   └── adapted/          ← YOUR modifications go here
│   │   ├── notebooks/
│   │   └── results/
│   │       ├── tables/
│   │       └── figures/
│   │
│   ├── 001_uba_utility_regression/
│   ├── 002_ts_resampling_strategies/
│   ├── ... (17 experiment folders)
│   └── 017_imbalanced_regression_pipeline/
│
├── scripts/                      ← ⚙️ Automation tools
│   ├── new_experiment.sh         ← Creates a new experiment from the template
│   ├── update_readme.py          ← Rebuilds the progress table in README.md
│   └── sync_from_excel.py        ← Syncs paper list from Google Drive Excel
│
├── shared/                       ← 🔗 Code shared across multiple experiments
│   ├── datasets/
│   │   └── README.md             ← Registry of shared datasets
│   ├── metrics/
│   │   ├── regression.py         ← RMSE, MAE, SMAPE implementations
│   │   └── classification.py     ← F1 score implementations
│   ├── visualization/
│   │   └── plot_utils.py         ← Publication-quality plot helpers
│   └── utils/
│       └── data_loading.py       ← Path helpers for the repo structure
│
├── docs/                         ← 📚 Reference documents
│   ├── paper_registry.md         ← Auto-generated list of all 43 papers
│   └── methodology.md            ← Scientific replication methodology
│
└── .github/
    └── ISSUE_TEMPLATE/
        └── new-experiment.md     ← GitHub issue template for new experiments
```

### Understanding the Two Key Boundaries

**Boundary 1: `_template/` is sacred — never edit it.**
It is the master blueprint. If you want to change what every future experiment looks like, edit the template. If you want to change an existing experiment, edit that experiment's folder directly.

**Boundary 2: `src/original/` is yours to fill manually.**
This directory inside each experiment folder is where you place the authors' original code. Git tracks it, but no script will touch it.

---
