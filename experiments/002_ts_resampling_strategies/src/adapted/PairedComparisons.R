library(performanceEstimation)

# Load merged results from results/merged_results.Rdata
merged_file <- "results/merged_results.Rdata"
if (!file.exists(merged_file)) {
  stop("Merged results file not found at ", merged_file, ". Please run merge_results.R first.")
}

load(merged_file)
# Object loaded is 'final_exp'

tasks <- taskNames(final_exp)
workflows <- workflowNames(final_exp)

cat("==========================================================\n")
cat(sprintf("Loaded merged results for %d dataset tasks across %d workflows.\n", 
            length(tasks), length(workflows)))

# Dynamically inspect metrics column names
sample_obj <- final_exp[[tasks[1]]][[workflows[1]]]
if (is.matrix(sample_obj@iterationsScores) || is.data.frame(sample_obj@iterationsScores)) {
  metric_cols <- colnames(sample_obj@iterationsScores)
} else {
  metric_cols <- names(sample_obj@iterationsScores)
}

cat("Available metrics:", paste(metric_cols, collapse = ", "), "\n")

target_metric <- "F1"
if (!target_metric %in% metric_cols) {
  f1_match <- grep("F1", metric_cols, value = TRUE, ignore.case = TRUE)
  if (length(f1_match) > 0) {
    target_metric <- f1_match[1]
  } else {
    target_metric <- metric_cols[1]
  }
}

cat(sprintf("Using target metric: '%s'\n", target_metric))
cat("==========================================================\n\n")

# Function to compute Win/Loss/Tie matrix safely
compute_WL <- function(res, base_wf, measure, sig = 0.05) {
  other_wfs <- setdiff(workflowNames(res), base_wf)
  WL <- matrix(0, ncol = 5, nrow = length(other_wfs))
  colnames(WL) <- c("Win", "sigWin", "Loss", "SigLoss", "Tie")
  rownames(WL) <- other_wfs
  
  for (t in taskNames(res)) {
    base_scores <- res[[t]][[base_wf]]@iterationsScores
    if (is.matrix(base_scores) || is.data.frame(base_scores)) {
      base_vec <- base_scores[, measure]
    } else {
      base_vec <- base_scores
    }
    base_mean <- mean(base_vec, na.rm = TRUE)
    
    for (wf in other_wfs) {
      wf_scores <- res[[t]][[wf]]@iterationsScores
      if (is.matrix(wf_scores) || is.data.frame(wf_scores)) {
        wf_vec <- wf_scores[, measure]
      } else {
        wf_vec <- wf_scores
      }
      wf_mean <- mean(wf_vec, na.rm = TRUE)
      
      diff <- wf_mean - base_mean
      
      p_val <- tryCatch({
        wt <- wilcox.test(wf_vec, base_vec, paired = TRUE, exact = FALSE)
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

baselines <- c("mc.lm", "mc.svm", "mc.mars", "mc.rf", "mc.rpart")

for (b in baselines) {
  if (b %in% workflows) {
    cat(sprintf("\n>>> Baseline Model: %s (Metric: %s) <<<\n", b, target_metric))
    wl_matrix <- compute_WL(final_exp, b, measure = target_metric, sig = 0.05)
    print(wl_matrix)
  }
}

# Average target metric score per Workflow across completed tasks
cat("\n==========================================================\n")
cat(sprintf("Average %s Score per Workflow Across %d Completed Datasets:\n", target_metric, length(tasks)))
cat("==========================================================\n")

mean_scores <- sapply(workflows, function(wf) {
  scores <- sapply(tasks, function(t) {
    obj <- final_exp[[t]][[wf]]@iterationsScores
    vec <- if (is.matrix(obj) || is.data.frame(obj)) obj[, target_metric] else obj
    mean(vec, na.rm = TRUE)
  })
  mean(scores, na.rm = TRUE)
})

rank_df <- data.frame(Workflow = names(mean_scores), Avg_Score = round(mean_scores, 4))
rank_df <- rank_df[order(-rank_df$Avg_Score), ]
rownames(rank_df) <- NULL
print(head(rank_df, 20))

# Save summary tables to disk
results_dir <- "results"
dir.create(results_dir, showWarnings = FALSE, recursive = TRUE)
write.csv(rank_df, file.path(results_dir, "workflow_rankings.csv"), row.names = FALSE)
cat(sprintf("\nRankings saved to %s/workflow_rankings.csv\n", results_dir))

cat("\nEvaluation Complete!\n")
