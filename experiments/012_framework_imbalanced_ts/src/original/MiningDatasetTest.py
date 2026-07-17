import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error
from sklearn.preprocessing import StandardScaler
import tensorflow as tf
from model_utils import TCN


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
    model.add((tf.keras.layers.Dense(1, activation=None)))
    return model


def get_tcn_model():
    tcn_kernel_size = 3
    tcn_layer_num = 6
    tcn_use_bias = True
    tcn_filter_num = 64
    tcn_kernel_initializer = 'random_normal'
    tcn_dropout_rate = 0.2
    tcn_dropout_format = "channel"
    tcn_activation = 'relu'
    tcn_final_activation = 'linear'
    tcn_final_stack_activation = 'relu'
    window_length = 180

    model = TCN(tcn_layer_num, tcn_kernel_size, tcn_filter_num, window_length, 1,
                tcn_use_bias, tcn_kernel_initializer, tcn_dropout_rate, tcn_dropout_format,
                tcn_activation, tcn_final_activation, tcn_final_stack_activation)
    return model


df = pd.read_csv("MiningProcess_Flotation_Plant_Database.csv", decimal=",")

df_valid = df[(df['date'] != '2017-04-10 00:00:00') & (df['date'] != '2017-03-10 01:00:00')]
y = np.round(df_valid['% Silica Concentrate'].values, 2)[::180]
x = df_valid.drop(['date', '% Silica Concentrate'], axis=1).values.reshape((-1, 180, df.shape[1] - 2))

train_x, test_x, train_y, test_y = train_test_split(x, y, test_size=0.2, random_state=42)
val_x, test_x, val_y, test_y = train_test_split(test_x, test_y, test_size=0.5, random_state=42)

for i in range(train_x.shape[2]):
    scaler = StandardScaler()
    train_x[:, :, i] = scaler.fit_transform(train_x[:, :, i])
    val_x[:, :, i] = scaler.transform(val_x[:, :, i])
    test_x[:, :, i] = scaler.transform(test_x[:, :, i])

sample_size = 2500
p = ihist(y)
p /= p.sum()
np.random.seed(42)
ihist_idx = np.random.choice(x.shape[0], size=sample_size, replace=False, p=p)

sample_ihist_x = x[ihist_idx]
sample_ihist_y = y[ihist_idx]
sample_ihist_train_x, sample_ihist_test_x, sample_ihist_train_y, sample_ihist_test_y = train_test_split(sample_ihist_x,
                                                                                                        sample_ihist_y,
                                                                                                        test_size=0.2,
                                                                                                        random_state=42)
sample_ihist_val_x, sample_ihist_test_x, sample_ihist_val_y, sample_ihist_test_y = train_test_split(sample_ihist_test_x,
                                                                                                    sample_ihist_test_y,
                                                                                                    test_size=0.5,
                                                                                                    random_state=42)

for i in range(train_x.shape[2]):
    scaler = StandardScaler()
    sample_ihist_train_x[:, :, i] = scaler.fit_transform(sample_ihist_train_x[:, :, i])
    sample_ihist_val_x[:, :, i] = scaler.transform(sample_ihist_val_x[:, :, i])
    sample_ihist_test_x[:, :, i] = scaler.transform(sample_ihist_test_x[:, :, i])

p = y.copy()
p /= p.sum()
np.random.seed(42)
sample_1_idx = np.random.choice(x.shape[0], size=sample_size, replace=False, p=p)

sample_1_x = x[sample_1_idx]
sample_1_y = y[sample_1_idx]
sample_1_train_x, sample_1_test_x, sample_1_train_y, sample_1_test_y = train_test_split(sample_1_x, sample_1_y,
                                                                                        test_size=0.2, random_state=42)
sample_1_val_x, sample_1_test_x, sample_1_val_y, sample_1_test_y = train_test_split(sample_1_test_x, sample_1_test_y,
                                                                                    test_size=0.5, random_state=42)

for i in range(train_x.shape[2]):
    scaler = StandardScaler()
    sample_1_train_x[:, :, i] = scaler.fit_transform(sample_1_train_x[:, :, i])
    sample_1_val_x[:, :, i] = scaler.transform(sample_1_val_x[:, :, i])
    sample_1_test_x[:, :, i] = scaler.transform(sample_1_test_x[:, :, i])

p = y.copy() ** 3
p /= p.sum()
np.random.seed(42)
sample_3_idx = np.random.choice(x.shape[0], size=sample_size, replace=False, p=p)

sample_3_x = x[sample_3_idx]
sample_3_y = y[sample_3_idx]
sample_3_train_x, sample_3_test_x, sample_3_train_y, sample_3_test_y = train_test_split(sample_3_x, sample_3_y,
                                                                                        test_size=0.2, random_state=42)
sample_3_val_x, sample_3_test_x, sample_3_val_y, sample_3_test_y = train_test_split(sample_3_test_x, sample_3_test_y,
                                                                                    test_size=0.5, random_state=42)

for i in range(train_x.shape[2]):
    scaler = StandardScaler()
    sample_3_train_x[:, :, i] = scaler.fit_transform(sample_3_train_x[:, :, i])
    sample_3_val_x[:, :, i] = scaler.transform(sample_3_val_x[:, :, i])
    sample_3_test_x[:, :, i] = scaler.transform(sample_3_test_x[:, :, i])

weights = ["mining_weights_normal", "mining_weights_fact_1", "mining_weights_fact_3", "mining_weights_ihist"]
test_sets = [test_x, sample_1_test_x, sample_3_test_x, sample_ihist_test_x]
results = [test_y, sample_1_test_y, sample_3_test_y, sample_ihist_test_y]
tcn = get_tcn_model()
lstm = get_lstm_model()
tcn.predict(test_x[:1, ...])
lstm.predict(test_x[:1, ...])
rmses_lstm = np.zeros((4, 30, 4))
rmses_tcn = np.zeros((4, 30, 4))
for w in range(len(weights)):
    for seed in range(30):
        lstm.load_weights(weights[w] + F"_{seed}.hdf5")
        tcn.load_weights("tcn_" + weights[w] + F"_{seed}.hdf5")
        for j in range(len(test_sets)):
            y_hat = lstm.predict(test_sets[j])
            error = np.round(mean_squared_error(results[j], y_hat, squared=False), 3)
            rmses_lstm[w, seed, j] = error
            y_hat = tcn.predict(test_sets[j])
            error = np.round(mean_squared_error(results[j], y_hat, squared=False), 3)
            rmses_tcn[w, seed, j] = error

np.savez("results.npz", rmses_lstm, rmses_tcn)
