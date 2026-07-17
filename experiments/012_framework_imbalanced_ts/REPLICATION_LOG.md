# Replication Log: A Framework for Imbalanced Time-Series Forecasting

This log tracks day-by-day progress of the replication effort.

---

<!-- Add new entries at the TOP of this file (most recent first) -->

## 2026-07-16/17 Full Replication Successful

**Time spent**: ~10h (compute time)

### What was done
- Adapted the original TensorFlow code to run natively on Apple Silicon without `tensorflow-addons`.
- Refactored the training script to support command-line arguments and deterministic seed injection.
- Created `run_parallel.py` to efficiently orchestrate multi-seed training across macOS CPU cores using `ProcessPoolExecutor`.
- Ran a full 30-seed replication spanning 240 models (LSTM and TCN across 4 configurations).
- Created `evaluate.py` to aggregate results into a final RMSE table.

### What worked
- Using `tf.keras.optimizers.legacy.Adam` successfully fixed the M-series GPU fallback issues.
- Modifying the parallelism scheme to limit to 4 workers kept temperatures perfectly safe (74°C vs 99°C) while maintaining high CPU utilization.
- The final results matched the original paper perfectly, confirming the hypothesis that TCN degrades on anomalous test sets while LSTM remains robust.

### Issues encountered
- `tensorflow-addons` is deprecated for modern TF on Apple Silicon, requiring a native re-implementation of `WeightNormalization`.
- Blindly spinning up 8 processes caused aggressive thread contention within TensorFlow, overheating the CPU to 99°C.

### Next steps
- Replication is fully complete. Review and finalize write-up.

## 2026-07-10 Initial Setup

**Time spent**: 0h 0m

### What was done
- Scaffolded experiment folder from template

### What worked
- N/A

### Issues encountered
- None

### Next steps
- Clone original code
- Set up environment
- Identify target results to replicate
