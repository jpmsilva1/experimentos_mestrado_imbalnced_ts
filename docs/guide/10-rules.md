## 10. Rules and Conventions You Must Never Break

These rules exist to ensure the repository stays usable 6 months from now.

| ❌ Never | ✅ Always |
|----------|-----------|
| Edit `experiments/_template/` for a one-off reason | Edit the specific experiment folder instead |
| Commit large data files (`.csv`, `.h5`, etc.) | Document the download source in the README |
| Commit the `.venv/` directory | Use `requirements.txt` for reproducibility |
| Change an experiment's status without running the update script | Run `python3 scripts/update_readme.py` after every status change |
| Write results outside `results/tables/` and `results/figures/` | Save tables as `.csv`, figures as `.png` |
| Skip the REPLICATION_LOG when things go wrong | Document failures in detail — they are scientifically valuable |
| Use generic commit messages like "update" | Use the `[EXP-NNN] action:` format |
| Install packages in the global Python environment | Always activate the experiment's `.venv` first |

---
