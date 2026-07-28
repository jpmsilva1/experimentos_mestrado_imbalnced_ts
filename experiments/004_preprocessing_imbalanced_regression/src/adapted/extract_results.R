library(performanceEstimation)

# Base directory for results
base_dir <- "../../results"
algorithms <- c("NNET", "RF", "SVM", "LM", "MARS") # In case LM and MARS are there
out_file <- "../../results/tables/final_metrics.csv"

# Create output dir if needed
dir.create(dirname(out_file), recursive = TRUE, showWarnings = FALSE)

results_list <- list()

# Loop over all algorithm directories
for (algo in algorithms) {
  algo_dir <- file.path(base_dir, algo)
  if (!dir.exists(algo_dir)) next
  
  rdata_files <- list.files(algo_dir, pattern = "\\.Rdata$", full.names = TRUE, all.files = TRUE)
  
  for (f in rdata_files) {
    cat("Processing:", f, "\n")
    
    # Load the object
    loaded_names <- tryCatch({
      load(f)
    }, error = function(e) {
      cat("Error loading", f, "\n")
      return(NULL)
    })
    
    if (is.null(loaded_names) || length(loaded_names) == 0) next
    
    res <- get(loaded_names[1])
    
    # Extract ds_name
    ds_names <- names(res)
    for (ds_name in ds_names) {
      wf_names <- names(res[[ds_name]])
      for (wf_name in wf_names) {
        # Some iterations might have failed, returning NULL or NA
        it_scores <- res[[ds_name]][[wf_name]]@iterationsScores
        if (!is.null(it_scores) && is.matrix(it_scores) && nrow(it_scores) > 0) {
          means <- colMeans(it_scores, na.rm = TRUE)
          
          # Parse workflow name to separate strategy and parameters
          # e.g. "WFsmote.svm.v24" -> strategy: "WFsmote", variant: "v24"
          parts <- strsplit(wf_name, "\\.")[[1]]
          strategy <- parts[1]
          if (length(parts) >= 3) {
            variant <- parts[3]
          } else {
            variant <- "default"
          }
          
          # Append to list
          results_list[[length(results_list) + 1]] <- data.frame(
            Dataset = ds_name,
            Algorithm = algo,
            Strategy = strategy,
            Variant = variant,
            Workflow = wf_name,
            ubaF = means["ubaF"],
            ubaprec = means["ubaprec"],
            ubarec = means["ubarec"],
            stringsAsFactors = FALSE
          )
        }
      }
    }
    # Clean up memory
    rm(list = loaded_names)
    gc()
  }
}

# Combine all results
if (length(results_list) > 0) {
  final_df <- do.call(rbind, results_list)
  # Remove row names
  rownames(final_df) <- NULL
  
  # Save to CSV
  write.csv(final_df, file = out_file, row.names = FALSE)
  cat("Success! Results extracted and saved to", out_file, "\n")
} else {
  cat("No valid data extracted.\n")
}
