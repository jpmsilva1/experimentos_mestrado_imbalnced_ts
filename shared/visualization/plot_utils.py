"""
Shared plotting utilities for consistent figure generation across experiments.
"""

import matplotlib.pyplot as plt
import matplotlib

# Use a clean, publication-ready style
matplotlib.rcParams.update({
    "figure.figsize": (8, 5),
    "figure.dpi": 150,
    "font.size": 12,
    "font.family": "serif",
    "axes.grid": True,
    "grid.alpha": 0.3,
    "savefig.bbox": "tight",
    "savefig.pad_inches": 0.1,
})


def save_figure(fig: plt.Figure, path: str, formats: list[str] | None = None) -> None:
    """Save a figure in multiple formats."""
    if formats is None:
        formats = ["png", "pdf"]
    for fmt in formats:
        fig.savefig(f"{path}.{fmt}", format=fmt)
    plt.close(fig)
