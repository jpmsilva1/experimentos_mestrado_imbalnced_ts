# PARALLELIZATION
# ponytail: forced sequential to avoid OOM on BEIJ datasets (151k rows)
NCORES <- 1
NUM_SPLITS <- 1
NUM_THREADS <- as.integer(Sys.getenv("SLURM_CPUS_PER_TASK", unset = parallel::detectCores() - 1))
library(doParallel)
cat(paste("\nUsing", NCORES, "(sequential outer mode), with", NUM_THREADS, "threads for ranger\n\n"))
registerDoParallel(cores=NCORES)

# LOADING LEARNING MODEL FUNCTIONS
library(ranger)
library(earth)
library(rpart)

# FILE PATHS
DATA_PATH <- "./extdata/"
UTILS_PATH <- "../R" # if package not installed
RESULTS_PATH <- "../../results/"

# LOADING PACKAGE CODE
library(STResamplingDSAA)
library(dplyr)
tosource <- list.files(UTILS_PATH, full.names = TRUE)
for(f in tosource) source(f)

# LOADING DATA
cat("\nLoading data sets...\n")
load(paste0(DATA_PATH, "dfs.Rdata"))
load(paste0(RESULTS_PATH, "inds_df.Rdata"))
load(paste0(RESULTS_PATH, "res_externalPrequential.Rdata")) # Load existing results!

# PARAMETRIZATION
models <- c("rpart", "earth", "ranger")
cpercs <- list()
cpercs[["stunder"]] <- c(0.2, 0.4, 0.6, 0.8, 0.95)
cpercs[["stover"]] <- c(0.5,1,2,3,4)
alphas <- c(0, 0.25, 0.5, 0.75, 1)

# WE ONLY WANT BEIJ DATASETS FOR THE PATCH
beij_datasets <- c('BEIJno', 'BEIJpm10', 'BEIJwind', 'BEIJpm25')
inds_df <- inds_df[beij_datasets]

EST_PARS <- list(nfolds = 10, 
                 window = "growing", 
                 fold.alloc.proc = "Tblock_SPall", 
                 removeSP = FALSE, 
                 time="time", 
                 site_id="station",
                 .keepTrain = TRUE,
                 .parallel = FALSE) # ponytail: sequential for everything to avoid OOM

THR_REL <- 0.9
EVAL_PARS <- list(eval.function = eval_stats, 
                  cf = 1.5, thr = THR_REL, beta = 1)
SEED <- 1234

# EVALUATION - ONLY PATCHING STUNDER AND STOVER
for(dfnm in names(inds_df)){
  
  cat(paste("\n\n############################"))
  cat(paste("\nTesting data", dfnm))
  
  df_list <- inds_df[[dfnm]]
  ind_df <- df_list$df
  
  stations <- data_list[[dfnm]]$stations
  
  # getting timestamps with right format AND THE FIX
  ind_df$time <- lubridate::ymd_hms(ind_df$time, truncated = 3)
  
  for(m in models){
    
    cat(paste(" and model", m, "\n"))
    
    WF_PARS <- list(model = m)
    if(m == "ranger"){
      WF_PARS <- c(WF_PARS, list(num.threads = NUM_THREADS))
    }
    
    # SPATIO-TEMPORAL BIAS RESAMPLING PATCH
    for(rsfun in c("stunder", "stover")){
      for(i in 1:length(cpercs[[rsfun]])){
        cperc <- cpercs[[rsfun]][[i]]
        for(a in alphas){
          
          RS_PARS <- list(resample=rsfun, 
            resample.pars = list(sites_sf=stations, alpha=a, thr.rel=THR_REL, C.perc=cperc, type="add"))

          parnm <- if(!is.list(cperc)) paste0(rsfun, "_cperc_", cperc, "_alpha_", a) else paste0(rsfun, "_cperc_", paste0(cperc, collapse="_"), "_alpha_", a)
          
          cat(paste("\nPatching", parnm))
          
          try( res[[m]][[dfnm]][[parnm]] <- estimates(ind_df, form=value~., 
                                                 estimator="prequential_eval",
                                                 est.pars = EST_PARS, 
                                                 workflow = "simple_workflow", 
                                                 wf.pars = c(WF_PARS, RS_PARS), 
                                                 evaluator = "evaluate", 
                                                 eval.pars = EVAL_PARS, 
                                                 seed=SEED) )
          
        }
      }
    }
    
    save(res, file=paste0(RESULTS_PATH, "res_externalPrequential.Rdata"))
  }
}
cat("\n\nPatch complete!\n")
