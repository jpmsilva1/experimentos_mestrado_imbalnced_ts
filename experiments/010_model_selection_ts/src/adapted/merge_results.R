results <- list()
for(i in 1:174) {
  file_path <- paste0("results/tables/results_tsdl_nf10_", i, ".rdata")
  if(file.exists(file_path)) {
    load(file_path) # loads 'est'
    results[[i]] <- est
  } else {
    warning(paste("Missing dataset ID:", i))
  }
}
save(results, file="results_tsdl_nf10.rdata")
cat("Successfully merged all .rdata files into results_tsdl_nf10.rdata!\n")
