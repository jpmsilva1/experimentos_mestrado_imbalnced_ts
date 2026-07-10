"""
Regression metrics commonly used across imbalanced time series experiments.

These are reference implementations. Individual experiments may use their own
metric implementations from their original codebases.
"""

import numpy as np


def rmse(y_true: np.ndarray, y_pred: np.ndarray) -> float:
    """Root Mean Squared Error."""
    return float(np.sqrt(np.mean((y_true - y_pred) ** 2)))


def mae(y_true: np.ndarray, y_pred: np.ndarray) -> float:
    """Mean Absolute Error."""
    return float(np.mean(np.abs(y_true - y_pred)))


def mape(y_true: np.ndarray, y_pred: np.ndarray, epsilon: float = 1e-8) -> float:
    """Mean Absolute Percentage Error."""
    return float(np.mean(np.abs((y_true - y_pred) / (y_true + epsilon))) * 100)


def smape(y_true: np.ndarray, y_pred: np.ndarray, epsilon: float = 1e-8) -> float:
    """Symmetric Mean Absolute Percentage Error."""
    numerator = np.abs(y_true - y_pred)
    denominator = (np.abs(y_true) + np.abs(y_pred)) / 2 + epsilon
    return float(np.mean(numerator / denominator) * 100)
