## 8. Git Workflow: How and When to Commit

### The Commit Message Convention

**Format:** `[EXP-NNN] action: description`

| Action | When | Example |
|--------|------|---------|
| `setup` | First scaffolding, cloning code | `[EXP-001] setup: clone UBA code and create venv` |
| `run` | Running experiments, generating results | `[EXP-001] run: reproduce Table 3 with original params` |
| `fix` | Fixing bugs or dependency issues | `[EXP-003] fix: adjust data path for local AEMO dataset` |
| `results` | Adding result tables or figures | `[EXP-001] results: add comparison table for RMSE metrics` |
| `docs` | Updating README or REPLICATION_LOG | `[EXP-001] docs: complete REPLICATION_LOG for session` |
| `refactor` | Restructuring code | `[EXP-001] refactor: move helper functions to adapted/` |

**For repo-wide changes:**
```
[REPO] docs: update README progress summary
[REPO] feat: add shared SERA metric implementation
```

### When to Commit

Commit after each of these milestones:
1. After scaffolding environment (status → 🔵)
2. After first successful run (status → 🟡)
3. After generating each set of results
4. After completing the experiment (status → 🟢)
5. After any significant REPLICATION_LOG update

### The Standard Commit Sequence

```bash
# 1. Check what changed
git status

# 2. Stage only what's relevant
git add experiments/NNN_folder_name/
git add README.md  # If you ran update_readme.py

# 3. Verify what's staged
git diff --staged --stat

# 4. Commit
git commit -m "[EXP-NNN] action: short description"

# 5. Push to GitHub
git push origin main
```

> ⚠️ **Never commit:** `*.csv` data files, `*.h5` model files, `.venv/` directories, or `__pycache__/`. These are all in `.gitignore`.

---
