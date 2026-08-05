rm(list=ls())
load("assets/datasets.rdata")
source("src/workflows.r")

library(tsensembler)

form <- target~.

num_cpus <- as.integer(Sys.getenv("SLURM_CPUS_PER_TASK", unset = parallel::detectCores() - 1))
if (is.na(num_cpus) || num_cpus < 1) {
  num_cpus <- 1
}

nfolds <- 10
outer_split <- .7

dir.create("results/tables", recursive = TRUE, showWarnings = FALSE)

parallel::mclapply(1:174, function(ID) {
  output_file <- paste0("results/tables/results_tsdl_nf10_", ID, ".rdata")
  
  if (file.exists(output_file)) {
    cat("Task ID:", ID, "already completed. Skipping.\n")
    return(NULL)
  }
  
  cat("Running task ID:", ID, "\n")
  ds <- ts_list[[ID]]
  
  est <-
    workflow.get_estimations(
      ds = ds,
      form = form,
      nfolds = nfolds,
      outer_split = outer_split
    )
  
  est$data <- ds
  
  save(est, file = output_file)
  cat("Finished task ID:", ID, "\n")
  
  return(NULL)
}, mc.cores = num_cpus)
