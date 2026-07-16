# Time Series Entity Resampling (TSER)

This repository contains the complementary code and experiments for the paper:  
**"Time series data augmentation as an imbalanced learning problem"**, published in the *EPIA Conference on Artificial Intelligence* (2024).

---

## Overview

This project addresses the **global-local trade-off** in time series forecasting. The goal is to perform **coreset selection**—identifying the most relevant subset of data from a global pool to optimize a model for a specific local entity or task.

By treating data augmentation/selection as an imbalanced learning problem, we propose a resampling approach that identifies the most informative historical observations to include in the training set.



---

## 🚀 Usage

### Quick Start
To see a basic demonstration of the entity resampling method, refer to the example script:
> `scripts/example.py`

### Reproducing Experiments
The experimental pipeline is organized into two phases:

1.  **Execution:** Run the scripts located in `scripts/run/*` to generate model estimations and resampling results.
2.  **Analysis:** Use the scripts in `scripts/run_analysis/*` to evaluate the performance and visualize the global-local trade-off.

---

## Citation

If you find this work or the TSER method useful, please cite the original paper:

```bibtex
@inproceedings{cerqueira2024time,
  title={Time series data augmentation as an imbalanced learning problem},
  author={Cerqueira, Vitor and Moniz, Nuno and In{\'a}cio, Ricardo and Soares, Carlos},
  booktitle={EPIA Conference on Artificial Intelligence},
  pages={335--346},
  year={2024},
  organization={Springer}
}
```