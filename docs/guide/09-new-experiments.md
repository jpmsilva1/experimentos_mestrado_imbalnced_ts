## 9. Adding a Brand New Experiment (Beyond the 17)

If you find a new paper you want to replicate that is not in the current index:

#### Step 1 — Run the scaffolding script

```bash
./scripts/new_experiment.sh 018 "new_paper_name" "Full Paper Title" "https://github.com/author/repo"
```

#### Step 2 — Add a row to the Experiment Index in README.md

Open `README.md` and add a new row to the `## 🗂️ Experiment Index` table:

```markdown
| 018 | Full Paper Title | 2025 | Author Names | ⚪ Pending | [GitHub](https://github.com/...) | [→](experiments/018_new_paper_name/) |
```

#### Step 3 — Update `docs/paper_registry.md`

If the paper is in the Excel file, run:
```bash
python3 scripts/sync_from_excel.py
```

If it's not, add it to the Excel file first, then run the sync script.

#### Step 4 — Commit

```bash
git add experiments/018_new_paper_name/ README.md docs/paper_registry.md
git commit -m "[REPO] feat: scaffold experiment 018 for Full Paper Title"
git push origin main
```

---
