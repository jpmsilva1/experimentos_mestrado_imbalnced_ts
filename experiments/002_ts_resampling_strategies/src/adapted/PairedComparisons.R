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

# Extract mean metrics summary table
tasks <- taskNames(final_exp)
workflows <- workflowNames(final_exp)

# Function to compute Win/Loss/Tie matrix safely
compute_WL <- function(res, base_wf, measure = "F1", sig = 0.05) {
  other_wfs <- setdiff(workflowNames(res), base_wf)
  WL <- matrix(0, ncol = 5, nrow = length(other_wfs))
  colnames(WL) <- c("Win", "sigWin", "Loss", "SigLoss", "Tie")
  rownames(WL) <- other_wfs
  
  for (t in taskNames(res)) {
    base_scores <- res[[t]][[base_wf]]@iterationsScores[, measure]
    base_mean <- mean(base_scores, na.rm = TRUE)
    
    for (wf in other_wfs) {
      wf_scores <- res[[t]][[wf]]@iterationsScores[, measure]
      wf_mean <- mean(wf_scores, na.rm = TRUE)
      
      diff <- wf_mean - base_mean
      
      # Wilcoxon test across the 50 Monte Carlo folds
      p_val <- tryCatch({
        wt <- wilcox.test(wf_scores, base_scores, paired = TRUE, exact = FALSE)
        wt$p.value
      }, error = function(e) 1.0)
      
      if (is.na(diff) || abs(diff) < 1e-9) {
        WL[wf, "Tie"] <- WL[wf, "Tie"] + 1
      } else if (diff > 0) {
        WL[wf, "Win"] <- WL[wf, "Win"] + 1
        if (!is.na(p_val) && p_val < sig) WL[wf, "sigWin"] <- WL[wf, "sigWin"] + 1
      } else {
        WL[wf, "Loss"] <- WL[wf, "Loss"] + 1
        if (!is.na(p_val) && p_val < sig) WL[wf, "SigLoss"] <- WL[wf, "SigLoss"] + 1
      }
    }
  }
  WL
}

cat("==========================================================\n")
cat("Paired Comparisons Matrix (Win / sigWin / Loss / SigLoss / Tie)\n")
cat("==========================================================\n")

baselines <- c("mc.lm", "mc.svm", "mc.mars", "mc.rf", "mc.rpart")

for (b in baselines) {
  if (b %in% workflowNames(final_exp)) {
    cat(sprintf("\n>>> Baseline Model: %s (Metric: F1 Score) <<<\n", b))
    wl_matrix <- compute_WL(final_exp, b, measure = "F1", sig = 0.05)
    print(wl_matrix)
  }
}

# Average F1 Score per Workflow across completed tasks
cat("\n==========================================================\n")
cat("Average F1 Score per Workflow Across All Completed Datasets:\n")
cat("==========================================================\n")

mean_f1 <- sapply(workflows, function(wf) {
  scores <- sapply(tasks, function(t) {
    mean(final_exp[[t]][[wf]]@iterationsScores[, "F1"], na.rm = TRUE)
  })
  mean(scores, na.rm = TRUE)
})

f1_df <- data.frame(Workflow = names(mean_f1), Avg_F1 = round(mean_f1, 4))
f1_df <- f1_df[order(-f1_df$Avg_F1), ]
rownames(f1_df) <- NULL
print(head(f1_df, 20))

# Save summary tables to disk
results_dir <- "results"
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)
write.csv(f1_df, file.path(results_dir, "workflow_f1_rankings.csv"), row.names = FALSE)
cat(sprintf("\nRankings saved to %s/workflow_f1_rankings.csv\n", results_dir))

cat("\nEvaluation Complete!\n")
