library(performanceEstimation)

# Load merged results from results/merged_results.Rdata
merged_file <- "results/merged_results.Rdata"
if (!file.exists(merged_file)) {
  stop("Merged results file not found at ", merged_file, ". Please run merge_results.R first.")
}

load(merged_file)
# Object loaded is 'final_exp'

cat("==========================================================\n")
cat(sprintf("Loaded merged results for %d dataset tasks across %d workflows.\n", 
            length(taskNames(final_exp)), length(workflowNames(final_exp))))
cat("==========================================================\n\n")

# 1. Print Overall Summary Metrics
cat("--- 1. OVERALL ESTIMATION SUMMARY ---\n")
tryCatch({
  summ <- estimationSummary(final_exp)
  print(summ)
}, error = function(e) {
  cat("Could not compute estimationSummary:", e$message, "\n")
})

# 2. Print Top Performers per Task
cat("\n--- 2. TOP PERFORMING WORKFLOWS PER TASK ---\n")
tryCatch({
  top_table <- topPerformers(final_exp)
  print(top_table)
}, error = function(e) {
  cat("Could not compute topPerformers:", e$message, "\n")
})

# 3. Print Ranked Workflows
cat("\n--- 3. RANKED WORKFLOWS ACROSS ALL DATASETS ---\n")
tryCatch({
  ranks <- rankWorkflows(final_exp)
  print(ranks)
}, error = function(e) {
  cat("Could not compute rankWorkflows:", e$message, "\n")
})

# 4. Safe Paired Comparisons Function
cat("\n--- 4. PAIRED COMPARISONS (Wilcoxon Signed-Rank Test) ---\n")

WLdef <- function(res, base, measure = "F1", sig = 0.05) {
  pres <- tryCatch(
    pairedComparisons(res, base, p.value = sig),
    error = function(e) NULL
  )
  
  if (is.null(pres)) {
    cat(sprintf("Could not compute pairedComparisons for base '%s'\n", base))
    return(NULL)
  }
  
  wf_names <- setdiff(workflowNames(res), base)
  WL <- matrix(0, ncol = 5, nrow = length(wf_names))
  colnames(WL) <- c("Win", "sigWin", "Loss", "SigLoss", "Tie")
  rownames(WL) <- wf_names
  
  w_test <- pres[[measure]]$WilcoxonSignedRank.test
  
  for (e in seq_along(taskNames(res))) {
    for (nm in wf_names) {
      if (!is.null(w_test) && nm %in% rownames(w_test)) {
        diff_val <- tryCatch(w_test[nm, 2, e], error = function(err) NA)
        p_val <- tryCatch(w_test[nm, 3, e], error = function(err) NA)
        
        if (!is.na(diff_val) && length(diff_val) == 1) {
          if (diff_val < 0) {
            WL[nm, "Win"] <- WL[nm, "Win"] + 1
            if (!is.na(p_val) && p_val < sig) WL[nm, "sigWin"] <- WL[nm, "sigWin"] + 1
          } else if (diff_val == 0) {
            WL[nm, "Tie"] <- WL[nm, "Tie"] + 1
          } else {
            WL[nm, "Loss"] <- WL[nm, "Loss"] + 1
            if (!is.na(p_val) && p_val < sig) WL[nm, "SigLoss"] <- WL[nm, "SigLoss"] + 1
          }
        }
      }
    }
  }
  WL
}

baselines <- c("mc.lm", "mc.svm", "mc.mars", "mc.rf", "mc.rpart")

for (b in baselines) {
  if (b %in% workflowNames(final_exp)) {
    cat(sprintf("\nBaseline Comparison vs '%s':\n", b))
    wl_res <- WLdef(final_exp, b, "F1", 0.05)
    if (!is.null(wl_res)) {
      print(head(wl_res, 10))
    }
  }
}

cat("\n==========================================================\n")
cat("Evaluation Complete!\n")
cat("==========================================================\n")
