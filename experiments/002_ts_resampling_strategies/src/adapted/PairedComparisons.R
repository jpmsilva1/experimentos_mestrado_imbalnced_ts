library(performanceEstimation)

# Load merged results from results/merged_results.Rdata
merged_file <- "results/merged_results.Rdata"
if (!file.exists(merged_file)) {
  stop("Merged results file not found at ", merged_file, ". Please run merge_results.R first.")
}

load(merged_file)
# Object loaded is 'final_exp'

cat(sprintf("Loaded merged results for %d dataset tasks across %d workflows.\n", 
            length(taskNames(final_exp)), length(workflowNames(final_exp))))

WLdef <- function(res, base, measure = "F1", sig = 0.05) {
  pres <- pairedComparisons(res, base, maxs = rep(TRUE, 3), p.value = sig)
  WL <- matrix(0, ncol = 5, nrow = (length(workflowNames(res)) - 1))
  colnames(WL) <- c("Win", "sigWin", "Loss", "SigLoss", "Tie")
  rownames(WL) <- setdiff(workflowNames(res), base)
  
  for (e in seq_along(taskNames(res))) {
    for (nm in setdiff(workflowNames(res), base)) {
      diff_val <- pres[[measure]]$WilcoxonSignedRank.test[nm, 2, e]
      p_val <- pres[[measure]]$WilcoxonSignedRank.test[nm, 3, e]
      
      if (!is.na(diff_val) && diff_val < 0) {
        WL[nm, 1] <- WL[nm, 1] + 1
        if (!is.na(p_val) && p_val < sig) WL[nm, 2] <- WL[nm, 2] + 1
      } else if (!is.na(diff_val) && diff_val == 0) {
        WL[nm, 5] <- WL[nm, 5] + 1
      } else {
        WL[nm, 3] <- WL[nm, 3] + 1
        if (!is.na(p_val) && p_val < sig) WL[nm, 4] <- WL[nm, 4] + 1
      }
    }
  }
  WL
}

cat("\n==========================================================\n")
cat("Paired Comparisons Summary (F1 Score, Wilcoxon Signed-Rank Test)\n")
cat("==========================================================\n\n")

# Top-level baseline comparisons
baselines <- c("mc.lm", "mc.svm", "mc.mars", "mc.rf", "mc.rpart")

for (b in baselines) {
  if (b %in% workflowNames(final_exp)) {
    cat(sprintf("\n--- Baseline: %s ---\n", b))
    res_matrix <- WLdef(final_exp, b, "F1", 0.05)
    print(res_matrix)
  }
}

# Rank and top performing workflows
cat("\n==========================================================\n")
cat("Top Performing Workflows Summary (Ranked by Avg F1 Score):\n")
cat("==========================================================\n")

top_table <- topPerformers(final_exp, maxs = rep(TRUE, 3))
print(top_table)

cat("\nDone! Paired comparisons evaluation complete.\n")
