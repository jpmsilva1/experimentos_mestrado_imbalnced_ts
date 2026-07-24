#!/bin/bash
# ==============================================================================
# Apuana Cluster — Python Virtualenv Bootstrap
# Usage: bash setup_env.sh <project_name> <requirements_file>
# Example: bash setup_env.sh my_experiment requirements.txt
#
# Idempotent: safe to run multiple times. Skips creation if env already exists.
# IMPORTANT: Run this inside tmux to survive VPN timeout (VPN drops ~every 30min)
# ==============================================================================

# Ensure micromamba is on PATH
export PATH="$HOME/.local/bin:$PATH"
eval "$(micromamba shell hook --shell bash)"

# PREVENT TMUX CORRUPTION: Disable progress bars which can garble tmux rendering on the cluster
export MAMBA_NO_PROGRESS=1

set -e

# --- Argument Validation ---
PROJECT_NAME="${1:-}"
REQUIREMENTS="${2:-requirements.txt}"

if [ -z "$PROJECT_NAME" ]; then
    echo "ERROR: Missing project name."
    echo "Usage: bash setup_env.sh <project_name> [requirements_file]"
    echo "Example: bash setup_env.sh my_experiment requirements.txt"
    exit 1
fi

VENV_PATH="$HOME/envs/$PROJECT_NAME"

echo "=========================================="
echo "Project:      $PROJECT_NAME"
echo "Env path:     $VENV_PATH"
echo "Requirements: $REQUIREMENTS"
echo "=========================================="

# --- Create Virtualenv (skip if already exists) ---
if [ -d "$VENV_PATH" ]; then
    echo "✅ Virtualenv already exists at $VENV_PATH — skipping creation."
else
    echo "Creating virtualenv..."
    python3 -m venv "$VENV_PATH"
    echo "✅ Virtualenv created."
fi

# --- Activate ---
source "$VENV_PATH/bin/activate"
echo "Activated: $(which python) — $(python --version)"

# --- Upgrade pip ---
pip install --upgrade pip --quiet

# --- Install Requirements ---
if [ -f "$REQUIREMENTS" ]; then
    echo "Installing from $REQUIREMENTS..."
    pip install -r "$REQUIREMENTS"
    echo "✅ Requirements installed."
else
    echo "WARNING: Requirements file '$REQUIREMENTS' not found. Skipping package install."
    echo "You can install packages manually: pip install <package>"
fi

# --- Sanity Check ---
echo ""
echo "--- Sanity Check ---"
python -c "
import sys
print(f'Python: {sys.version}')
try:
    import torch
    print(f'PyTorch: {torch.__version__}')
    print(f'CUDA available: {torch.cuda.is_available()}')
    if torch.cuda.is_available():
        print(f'GPU: {torch.cuda.get_device_name(0)}')
except ImportError:
    print('PyTorch: not installed (OK if not needed)')
"

echo ""
echo "=========================================="
echo "✅ Environment '$PROJECT_NAME' is ready."
echo "Activate with: source $VENV_PATH/bin/activate"
echo "=========================================="
