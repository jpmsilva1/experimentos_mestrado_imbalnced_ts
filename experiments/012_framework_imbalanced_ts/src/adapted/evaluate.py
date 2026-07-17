"""
evaluate.py (adapted from MiningDatasetTest.py)

Key changes from original:
1. Loads weights from a configurable --weights-dir.
2. Accepts --seeds and --data-path arguments.
3. Device-agnostic: no hardcoded gpu:0.
4. Saves structured results to --output-path as a .npz file.
5. Prints a summary table matching the paper's README format.
6. Uses modern .h5 weight format.
"""
import argparse
import os

import numpy as np
import pandas as pd
import tensorflow as tf
from sklearn.metrics import mean_squared_error
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

from model_utils import TCN


def parse_args():
    parser = argparse.ArgumentParser(description="Evaluate trained LSTM and TCN on the Mining dataset.")
    parser.add_argument("--data-path", type=str, default="MiningProcess_Flotation_Plant_Database.csv",
                        help="Path to the Kaggle mining CSV file.")
    parser.add_argument("--weights-dir", type=str, default="weights",
                        help="Directory where trained weights are stored.")
    parser.add_argument("--output-path", type=str, default="results/results.npz",
                        help="Path to save the .npz results file.")
    parser.add_argument("--seeds", type=int, default=30,
                        help="Number of seeds that were used during training.")
    parser.add_argument("--sample-size", type=int, default=2500)
    return parser.parse_args()


def ihist(target, bins=None, hist=None):
    if bins is None or hist is None:
        hist, bins = np.histogram(target, bins="auto")
    idx = np.digitize(target, bins[:-1]) - 1
    res = hist[idx] + 0.01
    return 1.0 / res


def get_lstm_model():
    model = tf.keras.Sequential()
    model.add(tf.keras.layers.LSTM(128, return_sequences=True))
    model.add(tf.keras.layers.LSTM(64))
    model.add(tf.keras.layers.Dense(1, activation=None))
    return model


def get_tcn_model():
    return TCN(
        tcn_layer_num=6, tcn_kernel_size=3, tcn_filter_num=64, window_size=180, forecast_horizon=1,
        use_bias=True, kernel_initializer='random_normal', tcn_dropout_rate=0.2,
        tcn_dropout_format="channel", tcn_activation='relu', tcn_final_activation='linear',
        tcn_final_stack_activation='relu',
    )


def scale_features(train, val, test):
    train, val, test = train.copy(), val.copy(), test.copy()
    for i in range(train.shape[2]):
        scaler = StandardScaler()
        train[:, :, i] = scaler.fit_transform(train[:, :, i])
        val[:, :, i] = scaler.transform(val[:, :, i])
        test[:, :, i] = scaler.transform(test[:, :, i])
    return train, val, test


def make_split(x, y, seed=42):
    tr_x, te_x, tr_y, te_y = train_test_split(x, y, test_size=0.2, random_state=seed)
    va_x, te_x, va_y, te_y = train_test_split(te_x, te_y, test_size=0.5, random_state=seed)
    return tr_x, va_x, te_x, tr_y, va_y, te_y


def main():
    args = parse_args()
    os.makedirs(os.path.dirname(args.output_path) or ".", exist_ok=True)

    print(f"Loading data from: {args.data_path}")
    df = pd.read_csv(args.data_path, decimal=",")
    df_valid = df[(df['date'] != '2017-04-10 00:00:00') & (df['date'] != '2017-03-10 01:00:00')]
    y = np.round(df_valid['% Silica Concentrate'].values, 2)[::180]
    x = df_valid.drop(['date', '% Silica Concentrate'], axis=1).values.reshape((-1, 180, df.shape[1] - 2))

    # Reproduce the same splits & sampling as training
    _, _, te_x_normal, _, _, te_y_normal = make_split(x, y)
    te_x_normal, _, _ = scale_features(te_x_normal, te_x_normal, te_x_normal)

    p = ihist(y); p /= p.sum()
    np.random.seed(42)
    idx = np.random.choice(x.shape[0], size=args.sample_size, replace=False, p=p)
    _, _, te_x_ihist, _, _, te_y_ihist = make_split(x[idx], y[idx])

    p = y.copy(); p /= p.sum()
    np.random.seed(42)
    idx = np.random.choice(x.shape[0], size=args.sample_size, replace=False, p=p)
    _, _, te_x_fact1, _, _, te_y_fact1 = make_split(x[idx], y[idx])

    p = y.copy() ** 3; p /= p.sum()
    np.random.seed(42)
    idx = np.random.choice(x.shape[0], size=args.sample_size, replace=False, p=p)
    _, _, te_x_fact3, _, _, te_y_fact3 = make_split(x[idx], y[idx])

    # configs[i] = (weight_prefix, test_x, test_y)
    # shape: (4 configs, 30 seeds, 4 test sets)
    config_names = ['normal', 'fact_1', 'fact_3', 'ihist']
    test_sets    = [te_x_normal, te_x_fact1, te_x_fact3, te_x_ihist]
    test_labels  = [te_y_normal, te_y_fact1, te_y_fact3, te_y_ihist]
    test_set_names = ['All data', 'SUS 1', 'SUS 3', 'IHS']

    # Build models and warm up to create weights
    lstm = get_lstm_model()
    tcn  = get_tcn_model()
    lstm.predict(te_x_normal[:1, ...], verbose=0)
    tcn.predict(te_x_normal[:1, ...],  verbose=0)

    rmses_lstm = np.zeros((len(config_names), args.seeds, len(test_sets)))
    rmses_tcn  = np.zeros((len(config_names), args.seeds, len(test_sets)))

    for w, config_name in enumerate(config_names):
        for seed in range(args.seeds):
            lstm_path = os.path.join(args.weights_dir, f"lstm_{config_name}_{seed}.weights.h5")
            tcn_path  = os.path.join(args.weights_dir, f"tcn_{config_name}_{seed}.weights.h5")

            if not os.path.exists(lstm_path) or not os.path.exists(tcn_path):
                print(f"  ⚠ Weights not found for {config_name} seed={seed}, skipping.")
                continue

            lstm.load_weights(lstm_path)
            tcn.load_weights(tcn_path)

            for j, (tx, ty) in enumerate(zip(test_sets, test_labels)):
                y_hat = lstm.predict(tx, verbose=0)
                rmses_lstm[w, seed, j] = np.round(mean_squared_error(ty, y_hat, squared=False), 3)

                y_hat = tcn.predict(tx, verbose=0)
                rmses_tcn[w, seed, j] = np.round(mean_squared_error(ty, y_hat, squared=False), 3)

            print(f"  ✓ Evaluated {config_name} seed={seed}")

    np.savez(args.output_path, rmses_lstm=rmses_lstm, rmses_tcn=rmses_tcn,
             config_names=config_names, test_set_names=test_set_names)
    print(f"\n✅ Results saved to: {args.output_path}")

    # Print summary table
    print("\n" + "=" * 80)
    print("RESULTS SUMMARY (RMSE mean ± std across seeds)")
    print("=" * 80)

    header = f"{'Model':<8} {'Trained on':<12}" + "".join(f"  {n:>18}" for n in test_set_names) + "    Max Error"
    print(header)
    print("-" * len(header))

    for w, config_name in enumerate(config_names):
        for model_name, rmses in [("LSTM", rmses_lstm), ("TCN", rmses_tcn)]:
            row_means = rmses[w].mean(axis=0)
            row_stds  = rmses[w].std(axis=0)
            max_err   = row_means.max()
            cells = "".join(f"  {m:.3f} ± {s:.3f}" for m, s in zip(row_means, row_stds))
            print(f"{model_name:<8} {config_name:<12}{cells}    {max_err:.3f}")
    print("=" * 80)


if __name__ == "__main__":
    main()
