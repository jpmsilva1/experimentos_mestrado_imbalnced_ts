## 6. File-by-File Reference: What to Write Where

### `experiments/NNN_folder_name/README.md`

This is the most important file in each experiment. Think of it as the **scientific report** for that replication.

| Section | What to write |
|---------|--------------|
| **Paper Metadata** | Fill in Authors, Year, Venue, DOI, Code URL, language, ARA link, Excel row |
| **Replication Status** | Keep this badge accurate — it drives the master dashboard |
| **Objective** | List exactly which tables/figures you plan to reproduce. Check them off when done. |
| **Environment Setup** | Write the exact commands to set up the environment from scratch. Assume a reader starts with nothing. |
| **How to Run** | Write the exact commands to run the experiment. |
| **Key Results** | Fill in the comparison table. This is the scientific output. |
| **Observations & Deviations** | Be honest about differences from the paper. |

### `experiments/NNN_folder_name/REPLICATION_LOG.md`

This is your **daily diary**. Write in it every time you work on the experiment. New entries go at the **top**.

Format:
```markdown
## [YYYY-MM-DD] What You Did

**Time spent**: Xh Xm

### What was done
- ...

### What worked
- ...

### Issues encountered
- ...

### Next steps
- ...
```

### `experiments/NNN_folder_name/requirements.txt`

Contains the **Python packages** needed to run the experiment. Update it after setting up the environment:
```bash
pip freeze > requirements.txt
```

### `experiments/NNN_folder_name/config/default.yaml`

The **experiment configuration** file. Use it to track the key parameters of your replication run:
- Random seeds
- Dataset paths
- Model hyperparameters
- Evaluation settings

This gives you a single place to see what parameters produced your results.

### `shared/metrics/regression.py` and `shared/metrics/classification.py`

**Only use these if the original paper doesn't provide its own metric implementations.** These are convenience implementations. The paper's own metrics always take priority.

---
