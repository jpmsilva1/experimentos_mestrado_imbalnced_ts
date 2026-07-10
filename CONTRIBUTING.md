# Contributing: Rules for this Repository

This document codifies the rules for adding, maintaining, and documenting experiments in this repository. Follow these rules **exactly** to maintain consistency.

---

## 1. Naming Conventions

### Experiment Folders
- **Format**: `NNN_short_descriptive_name/`
- **NNN**: Zero-padded 3-digit number, assigned sequentially (001, 002, ..., 999)
- **short_descriptive_name**: Snake_case, max 40 characters, descriptive of the paper's core contribution
- **Examples**:
  - `001_uba_utility_regression/`
  - `002_ts_resampling_strategies/`
  - `015_resampling_imbalanced_regression/`

### Branch Names (optional, for complex experiments)
- **Format**: `exp/NNN-short-description`
- **Example**: `exp/001-uba-utility-regression`

---

## 2. Adding a New Experiment

### Step-by-step procedure:

1. **Scaffold** the experiment folder:
   ```bash
   ./scripts/new_experiment.sh NNN "folder_name" "Paper Title" "https://code-url"
   ```
   This copies `experiments/_template/` to `experiments/NNN_folder_name/` and pre-fills the README.

2. **Manually insert** the original code into `src/original/`:
   - Copy or clone the paper's source code into the experiment's `src/original/` directory
   - Place any datasets into the appropriate location (local or `shared/datasets/`)
   - This step is **always done by the user**, never automated

3. **Fill in** the experiment README:
   - Complete all metadata fields (authors, year, venue, DOI)
   - Specify which tables/figures from the paper you intend to replicate
   - Document environment setup steps

4. **Update the root README**:
   ```bash
   python3 scripts/update_readme.py
   ```
   Or manually add a row to the Experiment Index table.

5. **Create a GitHub Issue** (optional but recommended):
   Use the "New Experiment Replication" issue template.

6. **Commit**:
   ```bash
   git add experiments/NNN_folder_name/
   git commit -m "[EXP-NNN] setup: scaffold experiment for Paper Title"
   ```

---

## 3. Commit Message Convention

**Format**: `[EXP-NNN] action: description`

**Valid actions**:
| Action | When to use |
|--------|------------|
| `setup` | Initial scaffolding, cloning code, creating environment |
| `run` | Running experiments, producing results |
| `fix` | Fixing bugs, adjusting paths, resolving dependency issues |
| `results` | Adding or updating result tables/figures |
| `docs` | Updating README, REPLICATION_LOG, or other documentation |
| `refactor` | Restructuring experiment code |

**For repo-level changes** (not specific to one experiment):
- `[REPO] action: description`

**Examples**:
```
[EXP-001] setup: clone original UBA code and create conda env
[EXP-001] run: reproduce Table 3 with original parameters
[EXP-001] results: add comparison table for RMSE metrics
[EXP-003] fix: adjust data path for local dataset location
[REPO] docs: update README progress summary
[REPO] feat: add shared SERA metric implementation
```

---

## 4. Experiment Lifecycle

Each experiment progresses through these stages:

```
⚪ Pending → 🔵 Setup → 🟡 In Progress → 🟢 Done
                                          ↘ 🔴 Blocked
```

### ⚪ Pending → 🔵 Setup
- [ ] Folder scaffolded from template
- [ ] Original code **manually copied** by user into `src/original/`
- [ ] Dependencies documented in `requirements.txt` or `environment.yml`
- [ ] Environment tested (imports work, no missing deps)

### 🔵 Setup → 🟡 In Progress
- [ ] Data downloaded or generated
- [ ] First successful run of original code
- [ ] Target results identified (which tables/figures to reproduce)

### 🟡 In Progress → 🟢 Done
- [ ] Key results reproduced with comparison table (paper vs. ours)
- [ ] All results saved in `results/` (tables as `.csv`, figures as `.png`)
- [ ] README fully completed with setup + run instructions
- [ ] REPLICATION_LOG documents the full history
- [ ] Any deviations from the paper are documented

### 🟡 In Progress → 🔴 Blocked
- [ ] Blocker clearly documented in README and REPLICATION_LOG
- [ ] GitHub Issue created with `blocked` label (if using Issues)

---

## 5. Replication Log Protocol

Every experiment has a `REPLICATION_LOG.md`. Update it **every time** you work on the experiment.

**Entry format**:
```markdown
## [YYYY-MM-DD] Action Title

**Time spent**: Xh Xm

### What was done
- Bullet points describing actions taken

### What worked
- Bullet points describing successes

### Issues encountered
- Bullet points describing problems (or "None")

### Next steps
- Bullet points describing what to do next
```

---

## 6. Environment Management

### Python experiments
- Use a `requirements.txt` per experiment
- Document the Python version in the README
- Prefer `venv` for isolation:
  ```bash
  cd experiments/NNN_folder_name/
  python3 -m venv .venv
  source .venv/bin/activate
  pip install -r requirements.txt
  ```

### R experiments
- Use an `renv.lock` or document R version + packages in README
- Include `install_packages.R` script if needed

### Conda experiments
- Use `environment.yml` instead of `requirements.txt`
- Document: `conda env create -f environment.yml`

---

## 7. Data Management

- **Do NOT commit large data files** (`.csv`, `.parquet`, `.h5`, etc.)
- Instead, provide download scripts in `shared/datasets/` or experiment-level `src/`
- Document data sources and download steps in the experiment README
- If data is small (<1MB), it MAY be committed with a note in the commit message

---

## 8. Results Management

- Save result tables as `.csv` files in `results/tables/`
- Save figures as `.png` files in `results/figures/`
- Always include the comparison table in the README (paper values vs. replicated values)
- Include the exact command used to produce each result
