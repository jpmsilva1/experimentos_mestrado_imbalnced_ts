import pandas as pd
import numpy as np
import os
from glob import glob
from imbalance_metrics import regression_metrics as rm

def evaluate():
    results_dir = "../../results/tables/none"
    data_dir = "src/original/data"
    
    datasets = [os.path.basename(f).replace('.csv', '') for f in sorted(glob(f'{data_dir}/*.csv'))][:3]
    models = ['BaggingRegressor', 'DecisionTreeRegressor', 'MLPRegressor', 'RandomForestRegressor', 'SVR', 'XGBRegressor']
    
    records = []
    
    for ds_name in datasets:
        print(f"Evaluating {ds_name}...")
        try:
            # Read original dataset to get true y
            df = pd.read_csv(f"{data_dir}/{ds_name}.csv")
            y_true_full = df[df.columns[0]].to_numpy()
        except FileNotFoundError:
            print(f"  Dataset {ds_name}.csv not found. Skipping.")
            continue
            
        for model in models:
            preds_dir = f"{results_dir}/{ds_name}/{model}"
            pred_files = glob(f"{preds_dir}/Pred*.csv")
            
            if not pred_files:
                # print(f"  No predictions found for {ds_name} - {model}")
                continue
                
            fold_seras = []
            
            for pf in pred_files:
                pred_df = pd.read_csv(pf)
                if pred_df.empty:
                    continue
                # col 0: index, col 1: y_pred
                indices = pred_df.iloc[:, 0].astype(int).to_numpy()
                y_pred = pred_df.iloc[:, 1].to_numpy()
                y_true = y_true_full[indices]
                
                try:
                    s = rm.sera(y_true, y_pred)
                    fold_seras.append(s)
                except Exception as e:
                    pass
                    
            if fold_seras:
                avg_sera = np.mean(fold_seras)
                records.append({
                    'Dataset': ds_name,
                    'Model': model,
                    'SERA_Baseline': avg_sera
                })
                
    if records:
        df_res = pd.DataFrame(records)
        df_res.to_csv("../../results/baseline_summary.csv", index=False)
        print("\n--- Baseline Results (SERA) ---")
        print(df_res.pivot(index='Dataset', columns='Model', values='SERA_Baseline'))
    else:
        print("No valid results found to evaluate.")

if __name__ == "__main__":
    evaluate()
