## 5. The Automation Scripts: What They Do and When to Use Them

### `new_experiment.sh` — Scaffolding New Experiments

**When to use it:** Only when adding an experiment **beyond the 17 already scaffolded** (i.e., experiment 018 onwards).

**What it does:**
1. Copies the entire `experiments/_template/` directory to a new folder.
2. Replaces all placeholder text (`[PAPER_TITLE]`, `[CODE_URL]`, etc.) in the new folder's files.
3. Sets today's date in the `REPLICATION_LOG.md`.

**How to use it:**
```bash
./scripts/new_experiment.sh NNN "folder_name" "Paper Title" "https://code-url"
```

**Real example:**
```bash
./scripts/new_experiment.sh 018 "smogn_regression" "SMOGN: a Pre-processing Approach for Imbalanced Regression" "https://github.com/nicktaonline/smogn"
```

**After running it, you will see:**
```
📁 Creating experiment: 018_smogn_regression
✅ Experiment scaffolded at: /Users/joaopms/Documents/Projeto_Mestrado/experiments/018_smogn_regression

Next steps:
  1. Edit README.md — fill in metadata fields
  2. Clone original code into src/original/
  3. Set up environment and update requirements.txt
  4. Run: python3 scripts/update_readme.py
  5. Commit: git add experiments/018_smogn_regression/ ...
```

> ⚠️ **Do NOT run this script** for experiments 001–017. They are already scaffolded.

---

### `update_readme.py` — Refreshing the Dashboard

**When to use it:** Every time you change the status badge in any experiment's `README.md`.

**What it does:**
1. Scans every folder under `experiments/NNN_*/` for a `README.md`.
2. Reads the `## Replication Status: [badge]` line from each one.
3. Updates the progress summary table (Done / In Progress / Setup / Pending / Blocked counts).
4. Updates today's date in the "Last updated" field.

**How to use it:**
```bash
# Dry run — shows what WOULD change, but writes nothing
python3 scripts/update_readme.py --check

# Live run — actually updates README.md
python3 scripts/update_readme.py
```

**When to run it:**
- Whenever you change an experiment's status badge
- Before every `git commit` that involves progress changes

> **Important:** This script only updates the progress tables. It does NOT change the Experiment Index table. If you add a brand new experiment and want it in the index, you must manually add a row there.

---

### `sync_from_excel.py` — Syncing Paper Metadata

**When to use it:** When you update the `Fichamento_Artigos.xlsx` file in Google Drive and want the changes reflected in `docs/paper_registry.md`.

**What it does:**
1. Opens `Fichamento_Artigos.xlsx` from your Google Drive (path is hardcoded in the script).
2. Reads all rows from the first sheet.
3. Groups papers into "with code" and "without code" based on the `Disponibilidade de Códigos?` column.
4. Writes a formatted markdown table to `docs/paper_registry.md`.

**How to use it:**
```bash
python3 scripts/sync_from_excel.py
```

**Expected output:**
```
✅ Paper registry written to: .../docs/paper_registry.md
   17 papers with code, 26 without code
```

> ⚠️ **Requirement:** `openpyxl` must be installed (`pip3 install openpyxl`).
> ⚠️ **Requirement:** Google Drive must be mounted and the file accessible at its hardcoded path.

---
