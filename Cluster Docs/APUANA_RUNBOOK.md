# APUANA Cluster — Operational Runbook

> **Status:** Active · **Version:** 1.0 · **Last Updated:** 2026-07-24  
> **Cluster:** Apuana HPC @ CIn/UFPE · **Maintained by:** jpms5

This runbook is the **single source of truth** for running Python and R ML experiments on the Apuana SLURM cluster. It is intentionally self-contained — no internet required to use it.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Connecting to Apuana](#2-connecting-to-apuana)
3. [The 30-Minute VPN Rule — Critical](#3-the-30-minute-vpn-rule)
4. [Cluster Overview](#4-cluster-overview)
5. [Partition Selection Guide](#5-partition-selection-guide)
6. [GPU Verification](#6-gpu-verification)
7. [Python Environment Setup](#7-python-environment-setup)
8. [R Environment Setup](#8-r-environment-setup)
9. [Writing a SLURM Job](#9-writing-a-slurm-job)
10. [Fault-Tolerant Job Arrays (MapReduce)](#10-fault-tolerant-job-arrays)
11. [Submitting & Monitoring Jobs](#11-submitting--monitoring-jobs)
12. [Retrieving Results](#12-retrieving-results)
13. [Quick Reference Card](#13-quick-reference-card)
14. [Troubleshooting — General](#14-troubleshooting--general)
15. [Troubleshooting — R-Specific](#15-troubleshooting--r-specific)

---

## 1. Prerequisites

Before submitting your first job, you need:

| Requirement | Details |
|---|---|
| **VPN** | FortiClient or OpenVPN connected to CIn/UFPE network |
| **SSH** | Terminal with SSH access (macOS Terminal, iTerm2, or WSL) |
| **Account** | Contact CIn HPC admins to register `jpms5@cin.ufpe.br` on the cluster |
| **Code on cluster** | `git clone` your repo onto the cluster, or `scp` your files |

---

## 2. Connecting to Apuana

```bash
ssh jpms5@slurm-client1.cin.ufpe.br
```

**First login:** You will be prompted to confirm the host fingerprint. Type `yes`.

After connecting, you land on a **login node** (`slurm-client1`). This is a shared gateway — do not run heavy computation here. All real work goes through SLURM.

---

## 3. The 30-Minute VPN Rule

> **This is the most common cause of lost work for new users.**

- The Apuana VPN session expires approximately every **30 minutes**.
- When VPN drops, your **SSH terminal session closes**.
- However, **SLURM jobs already submitted continue running** — they are fully detached.

### What this means in practice

| Action | VPN Drop Behavior |
|---|---|
| `sbatch job.slurm` then close terminal | ✅ Job continues normally |
| Running `pip install` in a bare SSH terminal | ❌ Install corrupted mid-way |
| Running `setup_r_env.sh` in a bare terminal | ❌ Environment left broken |
| Running `setup_r_env.sh` inside `tmux` | ✅ Install continues after reconnect |

### The Rule

**Always use `tmux` before any interactive setup:**

```bash
# Start a persistent session
tmux new -s work

# Run your setup (can take 10-30 min)
bash setup_r_env.sh my_project conda_pkgs.txt r_pkgs.txt

# If VPN drops: reconnect SSH, then:
tmux attach -t work
```

---

## 4. Cluster Overview

Check live cluster status:

```bash
sinfo -o "%P %l %G %c %m %D"
```

### Partition Summary

| Partition | Time Limit | Max GPUs | Max CPUs | Max RAM | Nodes |
|---|---|---|---|---|---|
| `debug` ⭐ | **30 min** | 3 | 96 | 512 GB | 2 |
| `install` | 30 min | 3 | 64 | 128 GB | 2 |
| `short-simple` | **2 days** | 7 | 96 | 512 GB | 8 |
| `short-complex` | 2 days | 7 | 96 | 512 GB | 5 |
| `long-simple` | **7 days** | 2 | 96 | 515 GB | 4 |
| `long-complex` | 7 days | 7 | 96 | 512 GB | 5 |
| `ebinstall` | ∞ | — | — | — | — |

> ⭐ `debug` is the **default partition**. Any `sbatch` without `--partition` goes here and will be killed at 30 minutes.

**Partitions to avoid:** `install`, `ebinstall`, `debug-admin` — these are reserved for system administration.

---

## 5. Partition Selection Guide

```
STEP 1 — How long will the job run?
  < 30 min  → debug          (syntax check / quick test ONLY)
  < 2 days  → short-simple   (single-node) or short-complex (multi-node)
  < 7 days  → long-simple    (single-node) ← default for all real experiments

STEP 2 — How many nodes?
  1 node    → -simple
  > 1 node  → -complex

STEP 3 — Never use: install, ebinstall, debug-admin
```

### Common Scenarios

| Scenario | Partition | Flags |
|---|---|---|
| Test if script runs without errors | `debug` | `--time=0:10:00` |
| Short Python DL experiment (< 2 days) | `short-simple` | `--gpus=1 --mem=64G` |
| Full experiment grid (2-7 days) | `long-simple` | `--gpus=1 --mem=128G` |
| R experiment (no GPU needed) | `long-simple` | `--mem=128G` (no `--gpus`) |

---

## 6. GPU Verification

**Before submitting your first GPU job**, verify GPU allocation works:

```bash
srun --pty --partition=debug --gpus=1 bash -c "nvidia-smi && echo '✅ GPU OK'"
```

This opens an interactive shell on a debug node with 1 GPU allocated and prints the GPU model and memory.

### GPU Flag Format

> **Apuana uses `--gpus=N`** — not `--gres=gpu:N`. Using the wrong flag will cause your job to fail silently or get no GPU.

```bash
# CORRECT for Apuana:
#SBATCH --gpus=1

# WRONG (do not use):
#SBATCH --gres=gpu:1
```

---

## 7. Python Environment Setup

Use `setup_env.sh` to create a per-project Python virtualenv.

```bash
# Run inside tmux if the setup takes more than a few minutes
bash "Cluster Docs/setup_env.sh" my_project_env requirements.txt
```

**What it does:**
1. Creates `$HOME/envs/my_project_env/` (skips if already exists — idempotent).
2. Upgrades pip.
3. Installs all packages from `requirements.txt`.
4. Prints a sanity check (Python version + CUDA availability).

**To use in a SLURM job:**
```bash
source $HOME/envs/my_project_env/bin/activate
```

### Python Script Best Practices (from production code)

Every Python experiment script should include these patterns at the top:

```python
import os, sys, multiprocessing, logging, random
import numpy as np
import torch

# 1. Read CPU allocation from SLURM (falls back gracefully on local machine)
num_cpus_env = os.environ.get("SLURM_CPUS_PER_TASK")
NUM_CPUS = int(num_cpus_env) if num_cpus_env else multiprocessing.cpu_count()

# 2. Bind all threading libraries to SLURM allocation
os.environ["OMP_NUM_THREADS"]      = str(NUM_CPUS)
os.environ["MKL_NUM_THREADS"]      = str(NUM_CPUS)
os.environ["OPENBLAS_NUM_THREADS"] = str(NUM_CPUS)
os.environ["NUMEXPR_NUM_THREADS"]  = str(NUM_CPUS)

# 3. Reproducibility — seed everything
SEED = 42
os.environ["PYTHONHASHSEED"] = str(SEED)
random.seed(SEED)
np.random.seed(SEED)
torch.manual_seed(SEED)
if torch.cuda.is_available():
    torch.cuda.manual_seed_all(SEED)
    torch.backends.cudnn.deterministic = True
    torch.backends.cudnn.benchmark = False

# 4. Dual logging (file + stdout — both captured by SLURM .out)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[
        logging.FileHandler("run.log"),
        logging.StreamHandler(sys.stdout)
    ]
)

# 5. Pre-create output directories
os.makedirs("results/data", exist_ok=True)
```

---

## 8. R Environment Setup

Use `setup_r_env.sh` to create a per-project R environment via micromamba.

> ⚠️ **Always run inside `tmux`** — R package compilation (especially spatial packages) takes 10-30 minutes and will break if VPN drops.

```bash
tmux new -s r-setup
bash "Cluster Docs/setup_r_env.sh" my_r_env conda_pkgs.txt r_pkgs.txt
```

**Package file format:**

`conda_pkgs.txt` — packages available on conda-forge:
```
r-ranger
r-earth
r-e1071
r-randomforest
r-forecast
```

`r_pkgs.txt` — CRAN/GitHub packages:
```
# CRAN packages (plain names)
performanceEstimation
DMwR2
# GitHub packages (prefix with 'github:')
github:paolocavagnolo/uba
github:mrfoliveira/STResampling-DSAA2019
```

**The 3-step install order (critical):**
1. `compilers` + `r-base` via micromamba — provides gcc/g++ for C package compilation
2. CRAN packages via `install.packages()` with reliable mirror
3. GitHub packages via `remotes::install_github()`

**To use in a SLURM job:**
```bash
eval "$(micromamba shell hook --shell bash)"
micromamba activate my_r_env
```

### R Script Best Practices

```r
# 1. Read CPU allocation from SLURM
n_threads <- as.integer(Sys.getenv("SLURM_CPUS_PER_TASK", unset = parallel::detectCores() - 1))

# 2. Set reliable CRAN mirror (prevents timeout on restricted networks)
options(repos = c(CRAN = "https://cloud.r-project.org/"))

# 3. For ranger models — use native threading, not doParallel socket clusters
model <- ranger::ranger(
  formula, data = train,
  num.threads = n_threads,  # C++ threading, no memory duplication
  seed = 42
)

# 4. Results: append one-at-a-time (fault-tolerant)
write.table(row_result, "results_task.csv",
            append = TRUE, sep = ",",
            col.names = !file.exists("results_task.csv"),
            row.names = FALSE)
```

---

## 9. Writing a SLURM Job

Two ready-to-use templates are provided in `Cluster Docs/`:
- `job_template.slurm` — Python
- `job_template_r.slurm` — R

### Every `#SBATCH` Flag Explained

```bash
#SBATCH --job-name=my-experiment    # Name shown in squeue. Keep short, no spaces.
#SBATCH --output=logs/%x_%j.out    # %x = job name, %j = job ID. Auto-created.
#SBATCH --error=logs/%x_%j.err     # Separate file for stderr.
#SBATCH --partition=long-simple    # ALWAYS set this explicitly.
#SBATCH --nodes=1                  # Number of compute nodes. Almost always 1.
#SBATCH --ntasks=1                 # Number of MPI tasks. Almost always 1.
#SBATCH --cpus-per-task=16         # CPU cores. Set to match your parallelism.
#SBATCH --gpus=1                   # GPUs. Omit entirely for R/CPU-only jobs.
#SBATCH --mem=64G                  # Total RAM. R jobs should use 128G minimum.
#SBATCH --time=7-00:00:00          # Wall-clock limit. Format: D-HH:MM:SS
#SBATCH --requeue                  # Auto-resubmit if preempted by the scheduler.
```

### Log Naming for Job Arrays

```bash
#SBATCH --output=logs/%x_%A_%a.out  # %A = array job ID, %a = task index
```

---

## 10. Fault-Tolerant Job Arrays

For experiments with multiple independent tasks (e.g., 30 datasets × N models), use SLURM job arrays to parallelise and protect against failures.

### Why Job Arrays?

- If one task crashes, the others keep running.
- `--requeue` handles node preemption automatically.
- Each task writes to its own file → **no NFS race conditions**.

### The MapReduce Pattern

**Step 1 — Map (submit):**

```bash
#SBATCH --array=0-29     # One task per dataset (30 total)
#SBATCH --requeue

TASK_ID=$SLURM_ARRAY_TASK_ID
OUTPUT_FILE="results/data/results_task_${TASK_ID}.csv"

# Skip if already done (enables safe reruns)
if [ -f "$OUTPUT_FILE" ]; then
    echo "Task $TASK_ID already completed. Skipping."
    exit 0
fi

python run_experiment.py --task-index "$TASK_ID" --output "$OUTPUT_FILE"
```

In Python, the skip check:
```python
if os.path.exists(output_file):
    logging.info(f"Task {task_id} already done. Exiting.")
    sys.exit(0)
```

In R:
```r
if (file.exists(output_file)) {
  cat("Task already completed. Skipping.\n")
  quit(status = 0)
}
```

**Step 2 — Monitor:**

```bash
squeue -u jpms5   # Watch array tasks complete
```

**Step 3 — Reduce (merge after all tasks finish):**

```bash
head -n 1 results/data/results_task_0.csv > final_results.csv
tail -q -n +2 results/data/results_task_*.csv >> final_results.csv
echo "Merged $(ls results/data/results_task_*.csv | wc -l) result files."
```

---

## 11. Submitting & Monitoring Jobs

### Submitting

**CRITICAL WARNING:** SLURM will instantly crash your job if the output directory specified in `#SBATCH --output=logs/...` does not exist. Always create it *before* submitting:
```bash
mkdir -p logs
```

```bash
sbatch job_template.slurm
# → Submitted batch job 123456
```

### Checking Status

```bash
# Your jobs only
squeue -u jpms5

# Verbose — shows reason for PENDING jobs
squeue -u jpms5 --format="%.10i %.12j %.8T %.10M %.6D %R"

# Live output (follow the log)
tail -f logs/my-experiment_123456.out

# All jobs on cluster (to gauge load)
squeue
```

### Post-Run Analysis

```bash
# Summary: state, runtime, max memory used
sacct -j 123456 --format=JobID,State,Elapsed,MaxRSS,ExitCode

# Full job details (includes reason for failure)
scontrol show job 123456
```

### Cancelling

```bash
scancel 123456        # Cancel one job
scancel -u jpms5      # Cancel ALL your jobs
```

---

## 12. Retrieving Results / Data Sync

### The Git Data Sync Trap (Silent Failure)
> **WARNING:** If you sync your project to the cluster using `git clone`, beware of `.gitignore`. Usually, `results/` or `data/` folders are gitignored. If your scripts expect pre-processed `.Rdata` or `.csv` files in those folders, they will silently fail or exit on the cluster if the folders are missing.
> **Fix:** Always transfer binary/data folders manually using `scp` or `rsync` outside of git.

### Option A — scp (direct copy)

**Copying a whole folder:**
```bash
# From your local machine:
scp -r jpms5@slurm-client1.cin.ufpe.br:~/path/to/results/ ./local_results/
```

**Copying a specific merged results file (example):**
```bash
scp jpms5@slurm-client1.cin.ufpe.br:~/Projeto_AM_Leandro_TabICL/cluster_apuana/final_run_results_v2.csv cluster_apuana/
```

### Option B — git push (preferred for reproducibility)

```bash
# On the cluster, after job finishes:
cd ~/my_project
git add results/
git commit -m "exp: cluster run results $(date +%Y-%m-%d)"
git push

# On your local machine:
git pull
```

---

## 13. Quick Reference Card

```
CONNECTION
  ssh jpms5@slurm-client1.cin.ufpe.br
  tmux new -s work          # Always! Before any setup.

ENVIRONMENT
  Python: bash setup_env.sh <name> requirements.txt
  R:      bash setup_r_env.sh <name> conda_pkgs.txt r_pkgs.txt

GPU CHECK
  srun --pty --partition=debug --gpus=1 bash -c "nvidia-smi"

SUBMIT
  sbatch job_template.slurm
  sbatch job_template_r.slurm

MONITOR
  squeue -u jpms5
  tail -f logs/<name>_<JOBID>.out
  sacct -j <JOBID> --format=JobID,State,Elapsed,MaxRSS,ExitCode

CANCEL
  scancel <JOBID>

MERGE ARRAY RESULTS
  head -n 1 results_task_0.csv > final_results.csv
  tail -q -n +2 results_task_*.csv >> final_results.csv

PARTITION GUIDE
  < 30 min    → debug
  < 2 days    → short-simple
  < 7 days    → long-simple  ← default
  CPU-only R  → no --gpus flag
  GPU Python  → --gpus=1
```

---

## 14. Troubleshooting — General

### Job stuck in `PENDING`

```bash
squeue -u jpms5 --format="%.10i %.12j %.8T %.10M %.6D %R"
```

Common reasons in the `%R` column:

| Reason | Meaning | Fix |
|---|---|---|
| `Resources` | Waiting for enough free CPUs/GPUs | Wait, or reduce `--cpus-per-task` |
| `QOSMaxCpuPerUserLimit` | Requested more CPUs than your quota allows (max 32 CPUs total) | Reduce `--cpus-per-task` (e.g., from 64 to 24) |
| `QOSMaxJobsPerUser` | Hit your personal job limit (max 4 running jobs) | Cancel old jobs with `scancel` or wait |
| `QOSMaxGRESPerUser` | Hit GPU quota | Reduce `--gpus` or cancel other GPU jobs |
| `Priority` | Other jobs have higher priority | Wait |

### Job immediately failed (`FAILED` state)

```bash
# Check the error log
cat logs/my-experiment_123456.err

# Check full SLURM details
scontrol show job 123456
```

Common causes:
- Script has a Python/R syntax error → test locally first.
- `virtualenv` or micromamba env not found → run setup script.
- `mkdir -p logs` missing → add to job script pre-flight.

### Tmux Garbled Output (Mamba Progress Bars)

- **Symptom:** Terminal text becomes completely garbled and unreadable while installing environments inside Tmux.
- **Root Cause:** Micromamba's dynamic download progress bars corrupt Tmux's terminal rendering on the cluster.
- **Fix:** Run `export MAMBA_NO_PROGRESS=1` before installing. (This is now hardcoded in our `setup_env.sh` scripts).

### Job ran but produced no output file

- Check that `results/data/` is pre-created with `os.makedirs("results/data", exist_ok=True)`.
- Check the `.err` log for exceptions.

### `CUDA out of memory`

- Reduce batch size in your script.
- Request more GPU memory — check `nvidia-smi` on debug node for VRAM details.
- Profile with `torch.cuda.memory_summary()`.

---

## 15. Troubleshooting — R-Specific

> All failures below are documented from real cluster sessions.

### R-5: VPN Drop During Setup (Most Common)

- **Symptom:** Conda env left in broken state; packages half-installed.
- **Fix:** Always use `tmux`. If broken: `micromamba env remove -n <name>` and restart setup.

### R-1: `doParallel` Socket Clusters → OOM Kill

- **Symptom:** SLURM kills job with `OUT_OF_MEMORY`.
- **Root Cause:** Socket clusters copy the entire R environment per core. 2 GB dataset × 8 cores = 16 GB instantly.
- **Fix:** For datasets > 20,000 rows, use sequential outer loops + native C++ threading:
  ```r
  # Instead of doParallel:
  ranger::ranger(formula, data, num.threads = as.integer(Sys.getenv("SLURM_CPUS_PER_TASK")))
  ```

### R-2: `"r2util" not resolved from current namespace (uba)`

- **Root Cause:** `install.packages()` silently skipped C compilation due to missing compilers.
- **Fix:**
  ```bash
  micromamba install -c conda-forge compilers   # Install compilers
  rm -rf scratch/uba/src/*.o scratch/uba/src/*.so  # Wipe stale artifacts
  R CMD INSTALL scratch/uba                     # Rebuild from source
  ```

### R-3: Memory Grows Unboundedly Per Fold

- **Root Cause:** `.keepTrain = TRUE` stores training data copies for every fold (30+ GB total).
- **Fix:** After each evaluation: `z$rawRes$train <- NULL`

### R-4: Job Hangs With 100% CPU, No Progress

- **Root Cause:** O(T × S²) nested R loops (e.g., `get_space_wts()`).
- **Fix:** Vectorize:
  ```r
  s_idx <- which(sites_in_T %in% paste0("SITE_", s))
  D_sub <- D[s, s_idx]
  w_space[s, timz == i] <- apply(D_sub, 1, min)
  ```

### R-5: `install.packages()` Hangs

- **Root Cause:** Default CRAN mirror unreachable from cluster nodes.
- **Fix:** Set explicitly: `options(repos = c(CRAN = "https://cloud.r-project.org/"))`

### R-6: Vector Memory Limit Reached

- **Symptom:** Script crashes on large datasets (>150k rows) with: `Error: vector memory limit of 16.0 Gb reached`.
- **Root Cause:** Sifting/applying operations row-by-row and storing them in a list creates hundreds of thousands of individual data frames in memory before they can be bound together.
- **Fix:** Implement **row chunking**. Process data in chunks of 5,000 rows, bind the chunk, and free it. This bounds memory to < 500MB instead of > 16GB.

### R-7: Cross-Platform Compilation Contamination

- **Symptom:** `file format not recognized` when installing R packages from source on the cluster.
- **Root Cause:** You synced your project from an Apple Silicon (ARM64) machine, uploading pre-compiled `*.o`/`*.so` files. The Linux cluster (x86_64) chokes on them.
- **Fix:** Run `find src -name "*.o" -delete` and `find src -name "*.so" -delete` in the package directory before running `R CMD INSTALL`.

### R-8: Modern C vs Legacy R Dependencies (GCC 15 / C23)

- **Symptom:** Legacy packages (`uba`) fail to compile with `incompatible pointer type` or `too many arguments to function`.
- **Root Cause:** Modern clusters use GCC 15 (C23 standard), which drops support for legacy C89 empty parameter lists `()`.
- **Fix:** Create a `src/Makevars` file in the package with: `PKG_CFLAGS = -std=gnu17 -Wno-incompatible-pointer-types -Wno-implicit-function-declaration`.
