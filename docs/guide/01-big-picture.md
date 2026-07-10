## 1. The Big Picture: What Is This Repository\?

This repository is your **private research laboratory notebook**, organized as code. Its goal is to systematically track and execute replications of 17 academic papers on imbalanced time series forecasting and regression.

### What "Replication" Means Here

You are **NOT** reimplementing papers from scratch. You are doing the following:

1. Taking the **original authors' source code** and placing it inside this repository.
2. **Running that code** in an isolated environment.
3. **Comparing the outputs** you get with the results claimed in the paper.
4. **Documenting everything**: what worked, what broke, and what differs.

This distinction is crucial: your job is to be a **scientific auditor**, not a reimplementer.

### The Boundary Between Automation and Manual Work

This repository makes a deliberate design choice:

| What is **automated** | What is **always manual** |
|----------------------|--------------------------|
| Creating experiment folder structure | Cloning/copying the original code |
| Replacing placeholder text in files | Downloading datasets |
| Updating the README progress table | Running the experiments |
| Syncing paper metadata from Excel | Interpreting results |
| Git commits (after you stage files) | Filling out the README comparison table |

> **The most important rule**: You, the researcher, control all data and code insertion. The scripts only handle bookkeeping.

---
