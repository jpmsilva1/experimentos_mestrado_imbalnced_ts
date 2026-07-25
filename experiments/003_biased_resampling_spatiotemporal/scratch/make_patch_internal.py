import re

with open('src/original/inst/exps_internalTuning.R', 'r') as f:
    code = f.read()

# 1. Load existing results instead of resetting res
code = code.replace(
    'res <- list()', 
    'load(paste0(RESULTS_PATH, "res_internalTuning.Rdata")) # LOAD INSTEAD OF WIPE'
)

# 2. Prevent wiping the model list
code = code.replace(
    'res[[m]] <- list()', 
    '# res[[m]] <- list() # PREVENT WIPING OTHER DATASETS'
)

# 3. Only run on BEIJ datasets
old_datasets = "inds_df <- inds_df[c('MESApol', 'NCDCPprec', 'TCEQOozone', 'TCEQTtemp', 'TCEQWwind', \n                     'RURALpm10', 'BEIJno', 'BEIJpm10', 'BEIJwind', 'BEIJpm25')]"
new_datasets = "inds_df <- inds_df[c('BEIJno', 'BEIJpm10', 'BEIJwind', 'BEIJpm25')] # ONLY PATCH BEIJ"
code = code.replace(old_datasets, new_datasets)

with open('src/original/inst/patch_internal.R', 'w') as f:
    f.write(code)
