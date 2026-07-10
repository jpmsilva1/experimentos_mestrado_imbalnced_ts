## 4. The Core Workflow: Step-by-Step Instructions

This is the exact sequence you must follow every time you work on a replication.

### Phase 0: Starting a New Session

Before doing anything else at the start of each work session:

```bash
# 1. Navigate to the repository
cd /Users/joaopms/Documents/Projeto_Mestrado

# 2. Check what's currently happening
git status
git log --oneline -5
```

This tells you exactly where you left off.

---

### Phase 1: Picking an Experiment

Open `README.md` in your browser or editor. The Experiment Index table shows all 17 experiments and their current status. Work in **priority order**:

- **P0 first** (001–005): Core thesis papers — resampling strategies for imbalanced regression
- **P1 second** (006–011): Methodology papers — performance estimation, model selection
- **P2 after** (012–015): Extended scope
- **P3 last** (016–017): Reference implementations

Pick the experiment with the **lowest number** that is not yet `🟢 Done`.

---

### Phase 2: Setting Up the Experiment Environment

This is the most important and most manual phase. Do it in order.

#### Step 2.1 — Read the paper and the ARA

Before touching any code, read:
1. The experiment's `README.md` — understand the target results you need to reproduce
2. The corresponding ARA in your Obsidian Vault (if it exists) — it contains distilled information about the paper's methodology and code

#### Step 2.2 — Copy the original code into `src/original/`

This is **always done manually**. You have two options:

**Option A: Clone the repository**
```bash
cd experiments/NNN_folder_name/src/
git clone https://github.com/author/repo original
```
> ⚠️ Do NOT use `git clone` inside the main repo without careful `.gitignore` handling. It's safer to clone elsewhere, then copy the folder.

**Option B: Copy downloaded files**
```bash
# After downloading the zip and extracting:
cp -r ~/Downloads/author-repo/ experiments/NNN_folder_name/src/original/
```

#### Step 2.3 — Create an isolated Python environment

**CRITICAL: Each experiment must have its own isolated environment.** Never install packages globally.

```bash
cd experiments/NNN_folder_name/

# Create the virtual environment
python3 -m venv .venv

# Activate it
source .venv/bin/activate

# Confirm you're in the right environment
which python3
# Should show: .../experiments/NNN_folder_name/.venv/bin/python3
```

#### Step 2.4 — Install dependencies

```bash
# Option A: If the paper has a requirements.txt
pip install -r src/original/requirements.txt

# Option B: If the paper has a setup.py or pyproject.toml
pip install -e src/original/

# Option C: Install manually (document every package you install)
pip install numpy pandas scikit-learn

# Save what you installed
pip freeze > requirements.txt
```

#### Step 2.5 — Test that everything imports without error

```bash
# Quick smoke test — confirm no broken imports
python3 -c "import sys; sys.path.insert(0, 'src/original'); print('imports OK')"
```

#### Step 2.6 — Change status to 🔵 Setup and commit

Once the environment works:
1. Open `experiments/NNN_folder_name/README.md`
2. Change `## Replication Status: ⚪ Pending` to `## Replication Status: 🔵 Setup`
3. Run the dashboard update:
   ```bash
   python3 scripts/update_readme.py
   ```
4. Commit:
   ```bash
   git add experiments/NNN_folder_name/ README.md
   git commit -m "[EXP-NNN] setup: clone original code and create venv"
   git push origin main
   ```

---

### Phase 3: Running the Replication

#### Step 3.1 — Identify the exact target results

Read the paper carefully. Decide which specific tables and figures you will reproduce. Add them to the experiment's `README.md` under the `Objective` section:

```markdown
## Objective

**Target results to replicate**:
- [ ] Table 3: RMSE comparison across resampling strategies on 5 datasets
- [ ] Figure 2: Performance vs. imbalance ratio curve
```

#### Step 3.2 — Run the original code with the original parameters

Always start with the **exact original parameters** the authors used. Do not change anything on the first run.

```bash
# Activate the environment first
source experiments/NNN_folder_name/.venv/bin/activate

# Navigate to the experiment directory
cd experiments/NNN_folder_name/

# Run the original code (the exact command varies by paper)
python3 src/original/main.py
# or: Rscript src/original/run_experiments.R
```

#### Step 3.3 — Update the REPLICATION_LOG immediately

Every time you do something, write it down in `REPLICATION_LOG.md`. This is your scientific diary. Entries go at the **top** of the file (most recent first).

```markdown
## [2026-07-15] First successful run attempt

**Time spent**: 2h 30m

### What was done
- Activated .venv and ran src/original/main.py
- Got a FileNotFoundError for the AEMO dataset

### What worked
- All imports resolved correctly
- Configuration loading worked

### Issues encountered
- The paper's data is not publicly available. Authors reference "private AEMO dataset".
- Contacted authors via email.

### Next steps
- Try with the public NASDAQ dataset as a proxy
- Wait for author response
```

#### Step 3.4 — Change status to 🟡 In Progress

Once you have your first successful run, update the status badge in the experiment's `README.md` from `🔵` to `🟡`.

---

### Phase 4: Recording Results

#### Step 4.1 — Save results to the right location

All outputs **must** go inside the experiment's `results/` directory:
- Tables → `results/tables/` as `.csv` files
- Figures → `results/figures/` as `.png` (and optionally `.pdf`) files

Name files descriptively:
```
results/
├── tables/
│   ├── table3_rmse_comparison.csv
│   └── table4_mae_by_dataset.csv
└── figures/
    ├── figure2_performance_vs_imbalance.png
    └── figure5_training_time.png
```

#### Step 4.2 — Fill the comparison table in README.md

This is the most important scientific output. For each metric you reproduce:

```markdown
## Key Results

| Metric | Paper Reports | Our Replication | Δ (absolute) | Notes |
|--------|--------------|-----------------|--------------|-------|
| RMSE (AEMO dataset) | 0.342 | 0.349 | +0.007 | Different random seed |
| SERA (AEMO dataset) | 0.891 | 0.887 | -0.004 | Within acceptable range |
```

#### Step 4.3 — Document deviations honestly

In the `Observations & Deviations` section:

```markdown
## Observations & Deviations

- **Library version**: Original used scikit-learn 0.24.2; we used 1.3.0. 
  The API for `RandomForestRegressor` changed in v1.0; adjusted accordingly.
- **Dataset**: Original code references a private AEMO energy dataset. 
  We used the publicly available GEFCom2014 as a proxy. Results are directionally consistent.
- **Seed**: Original paper does not specify a seed. We used seed=42 for reproducibility.
```

---

### Phase 5: Marking Complete and Committing

#### Step 5.1 — Mark checkboxes done in README

Check off every target result you successfully reproduced:

```markdown
**Target results to replicate**:
- [x] Table 3: RMSE comparison across resampling strategies on 5 datasets
- [x] Figure 2: Performance vs. imbalance ratio curve
```

#### Step 5.2 — Change status to 🟢 Done

Change `## Replication Status: 🟡 In Progress` to `## Replication Status: 🟢 Done`.

#### Step 5.3 — Run the update script and commit

```bash
# Update the main dashboard
python3 scripts/update_readme.py

# Stage all changes
git add experiments/NNN_folder_name/ README.md

# Commit with a descriptive message
git commit -m "[EXP-NNN] results: reproduce Table 3 and Figure 2"

# Push
git push origin main
```

---
