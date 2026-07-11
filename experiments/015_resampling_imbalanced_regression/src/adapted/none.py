from joblib import Parallel, delayed
import pandas as pd
from sklearn.model_selection import train_test_split, RepeatedKFold, GridSearchCV, KFold
from sklearn.tree import DecisionTreeRegressor
from sklearn.neural_network import MLPRegressor
from sklearn.svm import SVR
from sklearn.ensemble import BaggingRegressor, RandomForestRegressor
from glob import glob
import numpy as np
import os
from xgboost import XGBRegressor
import itertools as it

import warnings
warnings.filterwarnings('ignore')

def repeatedKfold(X, y, dataset_name):

  outer = RepeatedKFold(n_splits=10, n_repeats=2, random_state=42)

  regressors = {
    'BG': BaggingRegressor(),
    'DT': DecisionTreeRegressor(),
    'MLP': MLPRegressor(),
    'RF': RandomForestRegressor(),
    'SVM': SVR(),
    'XG': XGBRegressor()
  }

  for regressor_name, regressor in regressors.items():
      print(regressor_name)
      for fold, (train_index, test_index) in enumerate(outer.split(X, y)):
            print("outer")
            print("Fold:", fold)
            X_train, X_test = X[train_index], X[test_index]
            y_train, y_test = y[train_index], y[test_index]

            model = regressor.fit(X_train, y_train)
            y_pred = model.predict(X_test)

            model_name = type(model).__name__

            pred = np.column_stack((test_index, y_pred))
            out_dir = '../../results/tables/none/{}/{}'.format(dataset_name, model_name)
            os.makedirs(out_dir, exist_ok=True)
            pd.DataFrame(pred).to_csv('{}/Pred{}_{}.csv'.format(out_dir, fold, model_name), index=False)

def processar_dataset(dataset):
    ds = pd.read_csv(dataset)
    dataset_name = dataset.split('/')[-1].replace('.csv', '')

    X = ds.drop([ds.columns[0]], axis = 1)
    y = ds[ds.columns[0]]

    X = X.to_numpy()
    y = y.to_numpy()

    repeatedKfold(X, y, dataset_name)

data_sets = sorted(glob(r'src/original/data/*.csv'))[:3]

num_jobs = 1

for dataset in data_sets:
    processar_dataset(dataset)
