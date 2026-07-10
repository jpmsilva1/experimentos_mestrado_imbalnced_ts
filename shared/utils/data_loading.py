"""
Shared data loading utilities.
"""

from pathlib import Path


def get_repo_root() -> Path:
    """Return the repository root directory."""
    current = Path(__file__).resolve()
    # Navigate up from shared/utils/ to repo root
    return current.parent.parent.parent


def get_experiment_dir(experiment_id: str) -> Path:
    """Return the path to a specific experiment directory.

    Args:
        experiment_id: e.g., "001_uba_utility_regression"
    """
    return get_repo_root() / "experiments" / experiment_id


def get_shared_datasets_dir() -> Path:
    """Return the path to the shared datasets directory."""
    return get_repo_root() / "shared" / "datasets"
