#!/bin/bash
# Run this script on the Apuana cluster to set up the environment
# IMPORTANT: Run this from inside a tmux or screen session!

set -e

echo "=== Initializing Micromamba ==="
eval "$(micromamba shell hook --shell bash)"

echo "=== Creating exp013_tser environment ==="
# Disable progress bars to prevent tmux from rendering garbage ANSI characters
export MAMBA_NO_PROGRESS=1
export MAMBA_NO_COLORS=1

# We use Python 3.10 as a stable base for the requirements
micromamba create -y -n exp013_tser python=3.10

echo "=== Activating environment ==="
micromamba activate exp013_tser

echo "=== Installing requirements ==="
# Install the exact dependencies required by the paper
pip install -r src/original/requirements.txt

echo "✅ Environment exp013_tser setup complete on the cluster!"
