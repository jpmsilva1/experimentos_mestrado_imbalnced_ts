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

# Extract metric names safely
metrics <- tryCatch(getMetricsNames(final_exp), error = function(e) NULL)
if (is.null(metrics) || length(metrics) == 0) {
  metrics <- c("prec", "rec", "F1")
}

cat("Available metrics:", paste(metrics, collapse = ", "), "\n")

target_metric <- "F1"
if (target_metric %in% metrics) {
  target_idx <- which(metrics == target_metric)
} else {
  target_idx <- length(metrics) # Default to 3rd column (F1)
  target_metric <- metrics[target_idx]
}

cat(sprintf("Target Metric for Evaluation: '%s' (Column index %d)\n", target_metric, target_idx))
cat("==========================================================\n\n")

# Helper function to extract iteration score vector for a given workflow and task
get_scores_vec <- function(res, task, wf, m_idx, m_name) {
  obj <- res[[task]][[wf]]@iterationsScores
  if (is.matrix(obj) || is.data.frame(obj)) {
    if (m_name %in% colnames(obj)) {
      return(obj[, m_name])
    } else if (ncol(obj) >= m_idx) {
      return(obj[, m_idx])
    } else {
      return(obj[, 1])
    }
  } else if (is.numeric(obj)) {
    return(obj)
  }
  return(rep(NA, 50))
}

# Function to compute Win/Loss/Tie matrix safely
compute_WL <- function(res, base_wf, m_idx, m_name, sig = 0.05) {
  other_wfs <- setdiff(workflowNames(res), base_wf)
  WL <- matrix(0, ncol = 5, nrow = length(other_wfs))
  colnames(WL) <- c("Win", "sigWin", "Loss", "SigLoss", "Tie")
  rownames(WL) <- other_wfs
  
  for (t in taskNames(res)) {
    base_vec <- get_scores_vec(res, t, base_wf, m_idx, m_name)
    base_mean <- mean(base_vec, na.rm = TRUE)
    
    for (wf in other_wfs) {
      wf_vec <- get_scores_vec(res, t, wf, m_idx, m_name)
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
    wl_matrix <- compute_WL(final_exp, b, target_idx, target_metric, sig = 0.05)
    print(wl_matrix)
  }
}

# Average target metric score per Workflow across completed tasks
cat("\n==========================================================\n")
cat(sprintf("Average %s Score per Workflow Across %d Completed Datasets:\n", target_metric, length(tasks)))
cat("==========================================================\n")

mean_scores <- sapply(workflows, function(wf) {
  scores <- sapply(tasks, function(t) {
    vec <- get_scores_vec(final_exp, t, wf, target_idx, target_metric)
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
write.csv(rank_df, file.path(results_dir, "workflow_f1_rankings.csv"), row.names = FALSE)
cat(sprintf("\nRankings saved to %s/workflow_f1_rankings.csv\n", results_dir))

cat("\nEvaluation Complete!\n")
