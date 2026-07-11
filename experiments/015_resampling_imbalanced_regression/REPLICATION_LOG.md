# Replication Log: Resampling Strategies for Imbalanced Regression: Survey and Empirical Analysis

This log tracks day-by-day progress of the replication effort.

---

<!-- Add new entries at the TOP of this file (most recent first) -->

## 2026-07-10 Initial Setup

**Time spent**: 0h 0m

### What was done
- Scaffolded experiment folder from template
- Cloned `JusciAvelino/imbalancedRegression` into `src/original/`
- Set up Miniconda installation for Python/R isolated environment

### What worked
- Repo successfully cloned
- Implementation plan finalized focusing on Appendix B and C validation on a data subset

### Issues encountered
- No local R environment initially, pivoted to Miniconda

### Next steps
- Complete Miniconda installation
- Create `exp015_imbalanced` conda environment with `python=3.10 r-base rpy2 jupyter`
- Modify `none.ipynb` and `resampling.ipynb` to test a subset of data
