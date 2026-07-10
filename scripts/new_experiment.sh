#!/usr/bin/env bash
# =============================================================================
# new_experiment.sh — Scaffold a new experiment from the template
# =============================================================================
# Usage:
#   ./scripts/new_experiment.sh NNN "folder_name" "Paper Title" "https://code-url"
#
# Example:
#   ./scripts/new_experiment.sh 018 "my_new_experiment" "My Paper Title" "https://github.com/author/repo"
#
# This script:
#   1. Copies experiments/_template/ to experiments/NNN_folder_name/
#   2. Replaces placeholders in README.md and config/default.yaml
#   3. Prints next steps
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE_DIR="${REPO_ROOT}/experiments/_template"

# --- Argument validation ---
if [ "$#" -lt 3 ]; then
    echo "Usage: $0 NNN \"folder_name\" \"Paper Title\" [\"code_url\"]"
    echo ""
    echo "Arguments:"
    echo "  NNN          Three-digit experiment number (e.g., 018)"
    echo "  folder_name  Snake_case short name (e.g., my_new_experiment)"
    echo "  Paper Title  Full paper title in quotes"
    echo "  code_url     (Optional) URL to original code repository"
    exit 1
fi

NUM="$1"
FOLDER_NAME="$2"
PAPER_TITLE="$3"
CODE_URL="${4:-}"

# Validate number format
if ! [[ "$NUM" =~ ^[0-9]{3}$ ]]; then
    echo "ERROR: Experiment number must be exactly 3 digits (e.g., 001, 018, 123)"
    exit 1
fi

TARGET_DIR="${REPO_ROOT}/experiments/${NUM}_${FOLDER_NAME}"

# Check if target already exists
if [ -d "$TARGET_DIR" ]; then
    echo "ERROR: Directory already exists: ${TARGET_DIR}"
    exit 1
fi

# --- Copy template ---
echo "📁 Creating experiment: ${NUM}_${FOLDER_NAME}"
cp -r "$TEMPLATE_DIR" "$TARGET_DIR"

# --- Replace placeholders in README.md ---
if [ -f "${TARGET_DIR}/README.md" ]; then
    sed -i '' "s|\[PAPER_TITLE\]|${PAPER_TITLE}|g" "${TARGET_DIR}/README.md"
    sed -i '' "s|\[CODE_URL\]|${CODE_URL}|g" "${TARGET_DIR}/README.md"
    sed -i '' "s|NNN_folder_name|${NUM}_${FOLDER_NAME}|g" "${TARGET_DIR}/README.md"
fi

# --- Replace placeholders in config ---
if [ -f "${TARGET_DIR}/config/default.yaml" ]; then
    sed -i '' "s|\[EXPERIMENT_NAME\]|${NUM}_${FOLDER_NAME}|g" "${TARGET_DIR}/config/default.yaml"
    sed -i '' "s|\[PAPER_TITLE\]|${PAPER_TITLE}|g" "${TARGET_DIR}/config/default.yaml"
fi

# --- Replace placeholders in REPLICATION_LOG.md ---
if [ -f "${TARGET_DIR}/REPLICATION_LOG.md" ]; then
    sed -i '' "s|\[PAPER_TITLE\]|${PAPER_TITLE}|g" "${TARGET_DIR}/REPLICATION_LOG.md"
    TODAY=$(date +%Y-%m-%d)
    sed -i '' "s|\[YYYY-MM-DD\]|${TODAY}|g" "${TARGET_DIR}/REPLICATION_LOG.md"
fi

echo "✅ Experiment scaffolded at: ${TARGET_DIR}"
echo ""
echo "Next steps:"
echo "  1. Edit ${TARGET_DIR}/README.md — fill in metadata fields"
echo "  2. Clone original code into ${TARGET_DIR}/src/original/"
echo "  3. Set up environment and update requirements.txt"
echo "  4. Run: python3 scripts/update_readme.py"
echo "  5. Commit: git add experiments/${NUM}_${FOLDER_NAME}/ && git commit -m '[EXP-${NUM}] setup: scaffold experiment for ${PAPER_TITLE}'"
