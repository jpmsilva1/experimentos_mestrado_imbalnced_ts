library(doParallel)

# ponytail: parallelism disabled — doParallel copies s_dist_mat + t_dist_mat
# to each worker. For large BEIJ datasets this causes OOM (78GB observed).
# Re-enable with parallel=TRUE + NCORES>1 if memory is not a constraint.
NCORES <- 1
NUM_SPLITS <- 1
cat(paste("\nUsing", NCORES, "(sequential mode)\n\n"))
registerDoParallel(cores=NCORES)

DATA_PATH <-  "./extdata/"
RESULTS_PATH <- "../../results/"
if(!dir.exists(RESULTS_PATH)) dir.create(RESULTS_PATH, recursive=TRUE)
UTILS_PATH <- "../R/" # if package not installed

# LOAD PACKAGE CODE

library(STResamplingDSAA)
library(dplyr)
tosource <- list.files(UTILS_PATH, full.names = TRUE)
for(f in tosource) source(f)

# LOAD DATA SETS

cat("Loading data sets...\n")
load(paste0(DATA_PATH, "dfs.Rdata"))
dfnms <- names(data_list)

# GENERATE SPATIO-TEMPORAL INDICATORS

if(file.exists(paste0(RESULTS_PATH, "inds_df.Rdata"))) {
  cat("Resuming from existing inds_df.Rdata...\n")
  load(paste0(RESULTS_PATH, "inds_df.Rdata"))
} else {
  inds_df <- list()
}
for(i in 1:length(data_list)){
  dfnm <- dfnms[i]
  
  ALPHA <- 0.25
  BETAS <- c(0.0250, 0.0375, 0.0500)
  
  if(!(dfnm %in% names(inds_df))){
    
    cat(paste("\n", dfnm))
    
    cat("\nCalculating spatial distance matrix...\n")
    # calculate spatial distance matrix for non-dependent X-val
    s.dist <- norm_scale(get_spatial_dist_mat(data_list[[dfnm]]$stations, site_id = "station"))
    cat("Calculating temporal distance matrix...\n")
    # calculate temporal distance matrix for non-dependent X-val
    t.dist <- norm_scale(get_time_dist_mat(data_list[[dfnm]]$df$time))
    
    cat("Get spatio-temporal indicators...\n")
    ind_df <- get_full_indicators(data_list[[dfnm]]$df, data_list[[dfnm]]$stations,
                                  k=8, var="value",
                                  betas=BETAS, alpha=ALPHA,
                                  stats = c("mean", "weighted.mean", "sd"), 
                                  ratios2add = c(TRUE,TRUE,FALSE),
                                  parallel=FALSE, nsplits=NUM_SPLITS,
                                  time_id="time", site_id="station") 
    inds_df[[dfnm]] <- list(df=ind_df, alpha=ALPHA, betas=BETAS)
    
    cat("\nSaving indicator data...\n")
    save(inds_df, file=paste0(RESULTS_PATH, "inds_df.Rdata"))
    
    # Free memory
    data_list[[dfnm]] <- NULL
    gc()
  }
}

