#!/bin/bash
# ==============================================================================
# Apuana Cluster — R Environment Bootstrap (via micromamba)
# Usage: bash setup_r_env.sh <project_name> [conda_packages_file] [r_packages_file]
# Example: bash setup_r_env.sh exp_003 conda_pkgs.txt r_pkgs.txt
#
# Idempotent: safe to run multiple times. Skips creation if env already exists.
# IMPORTANT: Run this inside tmux to survive VPN timeout (VPN drops ~every 30min)
#
# Package install order (CRITICAL for C-compiled packages like uba/ranger):
#   Step 1 — Install compilers + R base via micromamba (conda-forge)
#   Step 2 — Install CRAN packages that are NOT on conda-forge via install.packages()
#   Step 3 — Install GitHub-only packages (uba, UBL, etc.) via remotes
# ==============================================================================

set -e

# --- Argument Validation ---
PROJECT_NAME="${1:-}"
CONDA_PKGS_FILE="${2:-}"   # optional: file with conda-forge package names (one per line)
R_PKGS_FILE="${3:-}"       # optional: file with CRAN/GitHub package names (one per line)

if [ -z "$PROJECT_NAME" ]; then
    echo "ERROR: Missing project name."
    echo "Usage: bash setup_r_env.sh <project_name> [conda_pkgs_file] [r_pkgs_file]"
    echo "Example: bash setup_r_env.sh exp_003 conda_pkgs.txt r_pkgs.txt"
    exit 1
fi

MICROMAMBA_BIN="$HOME/.local/bin/micromamba"

echo "=========================================="
echo "Project:    $PROJECT_NAME"
echo "Conda pkgs: ${CONDA_PKGS_FILE:-'(none)'}"
echo "R pkgs:     ${R_PKGS_FILE:-'(none)'}"
echo "=========================================="

# ==============================================================================
# STEP 0 — Install micromamba if absent
# ==============================================================================
if ! command -v micromamba &> /dev/null && [ ! -f "$MICROMAMBA_BIN" ]; then
    echo "Installing micromamba..."
    mkdir -p "$HOME/.local/bin"
    curl -Ls https://micro.mamba.pm/api/micromamba/linux-64/latest \
        | tar -xvj -C "$HOME/.local/bin/" --strip-components=1 bin/micromamba
    echo "✅ micromamba installed at $MICROMAMBA_BIN"
else
    echo "✅ micromamba already installed."
fi

# Ensure micromamba is on PATH
export PATH="$HOME/.local/bin:$PATH"
eval "$(micromamba shell hook --shell bash)"

# PREVENT TMUX CORRUPTION: Disable progress bars which can garble tmux rendering on the cluster
export MAMBA_NO_PROGRESS=1
# PREVENT NFS LOCK FREEZES: Disable lockfiles on networked home directory
export MAMBA_USE_LOCKFILES=false
export CONDA_USE_LOCKFILES=false

# ==============================================================================
# STEP 1 — Create conda env with R base + compilers (MUST be first)
# Compilers must be installed BEFORE any R packages that need C compilation
# (e.g., uba, ranger, sf, lwgeom).
# ==============================================================================
if micromamba env list | grep -q "^${PROJECT_NAME} "; then
    echo "✅ Conda env '$PROJECT_NAME' already exists — skipping creation."
else
    echo "Creating conda env '$PROJECT_NAME' with R 4.3 + compilers..."

    # PREVENT NFS LOCKING: Force mamba to cache in local node storage (/tmp)
    # instead of the networked home directory, avoiding database lock crashes.
    export MAMBA_CACHE_DIR="/tmp/$USER/mamba_cache"
    mkdir -p "$MAMBA_CACHE_DIR"

    # Base packages always installed: r-base + compilers (mandatory for C packages)
    BASE_PKGS="r-base=4.3 compilers"

    # Add extra conda-forge packages from file if provided
    EXTRA_PKGS=""
    if [ -f "$CONDA_PKGS_FILE" ]; then
        # Read packages, prefix each with 'r-' if not already prefixed
        while IFS= read -r pkg || [ -n "$pkg" ]; do
            [[ -z "$pkg" || "$pkg" == \#* ]] && continue  # skip empty/comments
            EXTRA_PKGS="$EXTRA_PKGS $pkg"
        done < "$CONDA_PKGS_FILE"
    fi

    micromamba create -n "$PROJECT_NAME" -c conda-forge $BASE_PKGS $EXTRA_PKGS -y
    echo "✅ Conda env created."
fi

# Activate env
micromamba activate "$PROJECT_NAME"
echo "R version: $(Rscript --version 2>&1)"

# ==============================================================================
# STEP 2 — Install CRAN packages not on conda-forge
# (Includes automatic fallback to GitHub CRAN mirror for archived packages)
# ==============================================================================
if [ -f "$R_PKGS_FILE" ]; then
    echo "Installing R packages from $R_PKGS_FILE..."

    # Build R vector of package names
    CRAN_PKGS=""
    while IFS= read -r pkg || [ -n "$pkg" ]; do
        [[ -z "$pkg" || "$pkg" == \#* || "$pkg" == github:* ]] && continue
        CRAN_PKGS="${CRAN_PKGS}'${pkg}',"
    done < "$R_PKGS_FILE"
    CRAN_PKGS="${CRAN_PKGS%,}"  # remove trailing comma

    if [ -n "$CRAN_PKGS" ]; then
        Rscript -e "
options(repos = c(CRAN = 'https://cloud.r-project.org/'))
if (!requireNamespace('remotes', quietly = TRUE)) install.packages('remotes')
pkgs <- c($CRAN_PKGS)
installed <- rownames(installed.packages())
to_install <- pkgs[!pkgs %in% installed]
if (length(to_install) > 0) {
  cat('Installing CRAN packages:', paste(to_install, collapse=', '), '\n')
  for (pkg in to_install) {
    tryCatch({
      install.packages(pkg, dependencies = TRUE)
    }, error = function(e) {
      cat('CRAN install failed for', pkg, '- attempting GitHub fallback (cran/', pkg, ')...\n', sep='')
      tryCatch({
        remotes::install_github(paste0('cran/', pkg), upgrade = 'never')
      }, error = function(e2) {
        cat('WARNING: Failed to install', pkg, 'from CRAN and GitHub.\n')
      })
    })
  }
} else {
  cat('All requested CRAN packages are already installed.\n')
}
"
        echo "✅ CRAN packages step complete."
    fi
fi

# ==============================================================================
# STEP 3 — Install GitHub-only packages
# Lines prefixed with 'github:' in r_pkgs_file (e.g., github:paolocavagnolo/uba)
# ==============================================================================
if [ -f "$R_PKGS_FILE" ]; then
    GITHUB_PKGS=""
    while IFS= read -r pkg || [ -n "$pkg" ]; do
        [[ "$pkg" == github:* ]] || continue
        repo="${pkg#github:}"
        GITHUB_PKGS="${GITHUB_PKGS}'${repo}',"
    done < "$R_PKGS_FILE"
    GITHUB_PKGS="${GITHUB_PKGS%,}"

    if [ -n "$GITHUB_PKGS" ]; then
        Rscript -e "
options(repos = c(CRAN = 'https://cloud.r-project.org/'))
if (!requireNamespace('remotes', quietly = TRUE)) install.packages('remotes')
repos <- c($GITHUB_PKGS)
for (repo in repos) {
  pkg_name <- basename(repo)
  if (!requireNamespace(pkg_name, quietly = TRUE)) {
    cat('Installing from GitHub:', repo, '\n')
    tryCatch({
      remotes::install_github(repo, upgrade = 'never')
    }, error = function(e) {
      cat('ERROR installing', repo, ':', conditionMessage(e), '\n')
    })
  } else {
    cat('Already installed:', pkg_name, '\n')
  }
}
"
        echo "✅ GitHub packages step complete."
    fi
fi

# ==============================================================================
# SANITY CHECK — Dynamic package verification
# ==============================================================================
echo ""
echo "--- Sanity Check ---"
Rscript -e "
cat('R version:', R.version\$major, '.', R.version\$minor, '\n', sep='')
cat('Library path:', .libPaths()[1], '\n')

check_pkg <- function(pkg) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat('  [OK] ', pkg, '\n', sep='')
  } else {
    cat('  [FAILED] ', pkg, ' (not found)\n', sep='')
  }
}

cat('Checking environment packages:\n')
pkgs_to_check <- c('base', 'compiler')
if (file.exists('$CONDA_PKGS_FILE')) {
  lines <- readLines('$CONDA_PKGS_FILE')
  for (l in lines) {
    if (grepl('^r-', l)) pkgs_to_check <- c(pkgs_to_check, gsub('^r-', '', l))
  }
}
if (file.exists('$R_PKGS_FILE')) {
  lines <- readLines('$R_PKGS_FILE')
  for (l in lines) {
    if (nchar(trimws(l)) == 0 || grepl('^#', l)) next
    pkg <- gsub('^github:[^/]+/', '', l)
    pkgs_to_check <- c(pkgs_to_check, pkg)
  }
}
pkgs_to_check <- unique(pkgs_to_check[!pkgs_to_check %in% c('gcc_linux-64', 'gxx_linux-64', 'zlib')])
for (p in pkgs_to_check) check_pkg(p)
"

echo ""
echo "=========================================="
echo "✅ R environment '$PROJECT_NAME' is ready."
echo "Activate with:"
echo "  eval \"\$(micromamba shell hook --shell bash)\""
echo "  micromamba activate $PROJECT_NAME"
echo "=========================================="
