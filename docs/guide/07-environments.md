## 7. Environment Management: Python, R, and Conda

### Python Experiments (most common)

```bash
cd experiments/NNN_folder_name/

# Create the isolated environment
python3 -m venv .venv

# Activate (macOS/Linux)
source .venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# When done working, deactivate
deactivate
```

> 💡 The `.venv/` directory is listed in `.gitignore` — it will NOT be committed. That's correct. The `requirements.txt` is what gets committed.

### R Experiments

For papers using R (e.g., UBA, IRon):
```bash
cd experiments/NNN_folder_name/

# Open R and install the needed packages
Rscript -e "install.packages(c('uba', 'performanceEstimation', 'randomForest'))"

# Create an install script for reproducibility
cat > install_packages.R << 'EOF'
install.packages(c("uba", "performanceEstimation"))
EOF
```

Document the R version in the README:
```bash
R --version | head -1
```

### Conda Experiments

For papers that require specific CUDA or complex binary dependencies:
```bash
conda env create -f src/original/environment.yml
conda activate experiment-name
```

---
