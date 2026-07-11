import pandas as pd
import numpy as np
import os
from glob import glob
from imbalance_metrics import regression_metrics as rm

def evaluate():
    results_dir = "../../results/tables/resampling"
    data_dir = "src/original/data"
    
    datasets = [os.path.basename(f).replace('.csv', '') for f in sorted(glob(f'{data_dir}/*.csv'))][:3]
    models = ['BaggingRegressor', 'DecisionTreeRegressor', 'MLPRegressor', 'RandomForestRegressor', 'SVR', 'XGBRegressor']
    strategies = ["SMT", "RO", "RU", "GN", "SG", "WC"]
    
    records = []
    
    for ds_name in datasets:
        print(f"Evaluating {ds_name}...")
        try:
            df = pd.read_csv(f"{data_dir}/{ds_name}.csv")
            y_true_full = df[df.columns[0]].to_numpy()
        except FileNotFoundError:
            continue
            
        for strategy in strategies:
            for model in models:
                preds_dir = f"{results_dir}/{strategy}/{ds_name}/{model}"
                pred_files = glob(f"{preds_dir}/Pred*.csv")
                
                if not pred_files:
                    continue
                    
                fold_seras = []
                
                for pf in pred_files:
                    pred_df = pd.read_csv(pf)
                    if pred_df.empty:
                        continue
                    indices = pred_df.iloc[:, 0].astype(int).to_numpy()
                    y_pred = pred_df.iloc[:, 1].to_numpy()
                    y_true = y_true_full[indices]
                    
                    try:
                        s = rm.sera(y_true, y_pred)
                        fold_seras.append(s)
                    except Exception:
                        pass
                        
                if fold_seras:
                    avg_sera = np.mean(fold_seras)
                    records.append({
                        'Dataset': ds_name,
                        'Strategy': strategy,
                        'Model': model,
                        'SERA': avg_sera
                    })
                
    if records:
        df_res = pd.DataFrame(records)
        df_res.to_csv("../../results/resampling_summary.csv", index=False)
        print("\n--- Resampling Results (SERA) ---")
        # Display Pivot per Dataset
        for ds in datasets:
            df_ds = df_res[df_res['Dataset'] == ds]
            if not df_ds.empty:
                print(f"\nDataset: {ds}")
                print(df_ds.pivot(index='Strategy', columns='Model', values='SERA'))
    else:
        print("No valid results found to evaluate.")

if __name__ == "__main__":
    evaluate()
