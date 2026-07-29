import os
import sys
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))
import warnings

import pandas as pd

from src.methods.learner import LightGBMOptim, BEST_PARAMS
from src.workflows.modeling import ModellingWorkflow
from src.workflows.data_reader import DataWorkflow
from src.common.errors import NotEnoughDataError

from config import (FORECASTING_HORIZON,
                    N_LAGS,
                    TEST_SIZE)

warnings.filterwarnings("ignore")

if len(sys.argv) > 1:
    DS = sys.argv[1]
else:
    DS = 'nn5_daily_without_missing'
IS_INDEPENDENT = False
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))), 'assets/results/by_series')
os.makedirs(OUTPUT_DIR, exist_ok=True)

ds = DataWorkflow.get_from_gluonts(DS)

if IS_INDEPENDENT:
    train, test, averages = \
        DataWorkflow.ind_train_test_split(dataset=ds,
                                          n_lags=N_LAGS,
                                          horizon=FORECASTING_HORIZON[DS],
                                          test_size=TEST_SIZE)
else:
    train, test, averages = \
        DataWorkflow.train_test_split(dataset=ds,
                                      n_lags=N_LAGS,
                                      horizon=FORECASTING_HORIZON[DS],
                                      test_size=TEST_SIZE)

import random
ts_names = [*train]
random.shuffle(ts_names)
for name in ts_names:
    filepath = f'{OUTPUT_DIR}/{DS}_{name}.csv'

    if os.path.exists(filepath):
        continue
    else:
        pd.DataFrame().to_csv(filepath)

    print(f'MODELLING SERIES: {name}')

    try:
        X_ts, Y_ts_or, Y_tr_or, avg = \
            ModellingWorkflow.get_xy(train=train,
                                     test=test,
                                     averages=averages,
                                     series_name=name)
    except NotEnoughDataError:
        continue

    mod = LightGBMOptim(params=BEST_PARAMS[DS])

    scores_df = \
        ModellingWorkflow.performance_estimation(algorithm=mod,
                                                 train=train,
                                                 X_test=X_ts,
                                                 Y_test=Y_ts_or,
                                                 Y_insample=Y_tr_or,
                                                 series_name=name,
                                                 series_avg=avg)

    print(scores_df.mean())

    scores_df.to_csv(filepath)
