## 11. Troubleshooting Common Problems

### "I ran `update_readme.py` but the status didn't change"

**Cause:** The status line in the experiment's `README.md` doesn't match the expected format.

**Check:** The status line must look **exactly** like:
```
## Replication Status: ⚪ Pending
```
Any extra spaces, different emoji, or different heading level will cause the script to miss it.

---

### "I get a permission denied error running `new_experiment.sh`"

**Solution:**
```bash
chmod +x scripts/new_experiment.sh
```

---

### "The `sync_from_excel.py` script says the Excel file is not found"

**Cause:** Google Drive is not mounted or the file path has changed.

**Check:**
```bash
ls "/Users/joaopms/Library/CloudStorage/GoogleDrive-jpms5@cin.ufpe.br/My Drive/Papers Mestrado - João/Fichamento_Artigos.xlsx"
```

If the file doesn't exist there, make sure Google Drive is open and synced.

---

### "I accidentally committed a large data file"

**Solution:**
```bash
# Remove the file from Git tracking but keep it locally
git rm --cached path/to/large/file.csv

# Add it to .gitignore
echo "experiments/NNN_folder_name/data/file.csv" >> .gitignore

# Commit the removal
git add .gitignore
git commit -m "[REPO] fix: untrack large data file from EXP-NNN"
git push origin main
```

---

### "I'm not sure which experiment to work on next"

Open `README.md`. The progress summary table shows the count in each status. Work on the lowest-numbered experiment that is `⚪ Pending` or `🔴 Blocked` — in that priority order.

---

### "The original code doesn't run at all — different Python version, broken deps"

This is common! Recommended approach:
1. Try installing the **exact versions** specified in the original `requirements.txt` (if it exists).
2. If that fails, try a `conda` environment with the paper's stated Python version.
3. Check GitHub Issues on the original repository — others may have solved it.
4. Document the problem in `REPLICATION_LOG.md` and set status to `🔴 Blocked`.
5. Try the next experiment and come back later.

---

*Last updated: 2026-07-10*
*Repository: https://github.com/jpmsilva1/experimentos_mestrado_imbalnced_ts*
