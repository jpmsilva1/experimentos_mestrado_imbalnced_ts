"""
train.py (adapted from MiningDataset.py)

Key changes from original:
1. Device-agnostic: removed hardcoded `with tf.device("gpu:0")`. TF auto-selects
   the best available device (Metal/MPS on Apple Silicon, CUDA on NVIDIA, or CPU).
2. Accepts --data-path argument instead of hardcoding CSV filename.
3. Accepts --seeds and --epochs arguments for a fast "dry-run" mode.
4. Saves weights to a configurable --output-dir directory.
5. Uses modern .keras format for checkpoints instead of deprecated .hdf5.
6. Replaced tensorflow-addons dependency (WeightNormalization now lives in model_utils).
"""
import argparse
import os

import numpy as np
import pandas as pd
import tensorflow as tf
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler

from model_utils import TCN


def parse_args():
    parser = argparse.ArgumentParser(description="Train LSTM and TCN on the Mining dataset (adapted).")
    parser.add_argument("--data-path", type=str, default="MiningProcess_Flotation_Plant_Database.csv",
                        help="Path to the Kaggle mining CSV file.")
    parser.add_argument("--output-dir", type=str, default="weights",
                        help="Directory to save model weights.")
    parser.add_argument("--seed", type=int, default=None,
                        help="Run a single specific seed. Overrides --seeds.")
    parser.add_argument("--seeds", type=int, default=30,
                        help="Number of random seeds to run sequentially (default=30).")
    parser.add_argument("--epochs", type=int, default=200,
                        help="Max epochs per model (default=200; use 5 for dry run).")
    parser.add_argument("--batch-size", type=int, default=64)
    parser.add_argument("--sample-size", type=int, default=2500,
                        help="Number of samples for the biased subsets.")
    return parser.parse_args()


def ihist(target, bins=None, hist=None):
    if bins is None or hist is None:
        hist, bins = np.histogram(target, bins="auto")
    idx = np.digitize(target, bins[:-1]) - 1
    # add small constant to avoid divisions by zero
    res = hist[idx] + 0.01
    return 1.0 / res


def get_lstm_model():
    model = tf.keras.Sequential()
    model.add(tf.keras.layers.LSTM(128, return_sequences=True))
    model.add(tf.keras.layers.LSTM(64))
    model.add(tf.keras.layers.Dense(1, activation=None))
    return model


def get_tcn_model():
    model = TCN(
        tcn_layer_num=6,
        tcn_kernel_size=3,
        tcn_filter_num=64,
        window_size=180,
        forecast_horizon=1,
        use_bias=True,
        kernel_initializer='random_normal',
        tcn_dropout_rate=0.2,
        tcn_dropout_format="channel",
        tcn_activation='relu',
        tcn_final_activation='linear',
        tcn_final_stack_activation='relu',
    )
    return model


def scale_features(train, val, test):
    """Fit scaler on train and apply to all splits. Returns scaled copies."""
    train = train.copy()
    val = val.copy()
    test = test.copy()
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


def train_and_save(model, name, train_x, train_y, val_x, val_y, output_dir, seed, epochs, batch_size):
    optimizer = tf.keras.optimizers.Adam()
    model.compile(optimizer, 'mse',
                  metrics=[tf.keras.metrics.MeanAbsoluteError(),
                           tf.keras.metrics.RootMeanSquaredError()])

    filepath = os.path.join(output_dir, f"{name}_{seed}.weights.h5")
    callbacks = [
        tf.keras.callbacks.EarlyStopping(monitor='val_loss', patience=25, min_delta=0.001),
        tf.keras.callbacks.ModelCheckpoint(filepath, monitor='val_loss', save_best_only=True,
                                           save_weights_only=True, mode='auto'),
    ]
    model.fit(train_x, train_y, validation_data=(val_x, val_y),
              epochs=epochs, batch_size=batch_size, callbacks=callbacks, verbose=0)
    print(f"  ✓ Saved: {filepath}")


def main():
    args = parse_args()
    os.makedirs(args.output_dir, exist_ok=True)

    print(f"Loading data from: {args.data_path}")
    df = pd.read_csv(args.data_path, decimal=",")

    df_valid = df[(df['date'] != '2017-04-10 00:00:00') & (df['date'] != '2017-03-10 01:00:00')]
    y = np.round(df_valid['% Silica Concentrate'].values, 2)[::180]
    x = df_valid.drop(['date', '% Silica Concentrate'], axis=1).values.reshape((-1, 180, df.shape[1] - 2))

    print(f"Dataset shape: x={x.shape}, y={y.shape}")

    # --- Build all sampling configurations ---
    configs = {}

    # 1) Normal (full data split)
    tr_x, va_x, te_x, tr_y, va_y, te_y = make_split(x, y)
    tr_x, va_x, te_x = scale_features(tr_x, va_x, te_x)
    configs['normal'] = (tr_x, va_x, te_x, tr_y, va_y, te_y)

    # 2) Inverse histogram sampling (IHS)
    p = ihist(y)
    p /= p.sum()
    np.random.seed(42)
    idx = np.random.choice(x.shape[0], size=args.sample_size, replace=False, p=p)
    tr_x, va_x, te_x, tr_y, va_y, te_y = make_split(x[idx], y[idx])
    tr_x, va_x, te_x = scale_features(tr_x, va_x, te_x)
    configs['ihist'] = (tr_x, va_x, te_x, tr_y, va_y, te_y)

    # 3) SUS 1 — probability ∝ y
    p = y.copy()
    p /= p.sum()
    np.random.seed(42)
    idx = np.random.choice(x.shape[0], size=args.sample_size, replace=False, p=p)
    tr_x, va_x, te_x, tr_y, va_y, te_y = make_split(x[idx], y[idx])
    tr_x, va_x, te_x = scale_features(tr_x, va_x, te_x)
    configs['fact_1'] = (tr_x, va_x, te_x, tr_y, va_y, te_y)

    # 4) SUS 3 — probability ∝ y³
    p = y.copy() ** 3
    p /= p.sum()
    np.random.seed(42)
    idx = np.random.choice(x.shape[0], size=args.sample_size, replace=False, p=p)
    tr_x, va_x, te_x, tr_y, va_y, te_y = make_split(x[idx], y[idx])
    tr_x, va_x, te_x = scale_features(tr_x, va_x, te_x)
    configs['fact_3'] = (tr_x, va_x, te_x, tr_y, va_y, te_y)

    # --- Training loop ---
    seed_list = [args.seed] if args.seed is not None else range(args.seeds)
    for seed in seed_list:
        print(f"\n=== Seed {seed}/{args.seeds if args.seed is None else 1} ===")
        np.random.seed(seed)
        tf.random.set_seed(seed)

        for config_name, (tr_x, va_x, _, tr_y, va_y, _) in configs.items():
            print(f"  Training config: {config_name}")

            lstm = get_lstm_model()
            tcn = get_tcn_model()
            # warm-up call to build the model
            lstm.predict(tr_x[:1, ...], verbose=0)
            tcn.predict(tr_x[:1, ...], verbose=0)

            train_and_save(lstm, f"lstm_{config_name}", tr_x, tr_y, va_x, va_y,
                           args.output_dir, seed, args.epochs, args.batch_size)
            train_and_save(tcn, f"tcn_{config_name}", tr_x, tr_y, va_x, va_y,
                           args.output_dir, seed, args.epochs, args.batch_size)

    print("\n✅ Training complete. Weights saved to:", args.output_dir)


if __name__ == "__main__":
    main()
