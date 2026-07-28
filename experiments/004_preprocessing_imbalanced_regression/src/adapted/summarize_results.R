library(dplyr)
library(tidyr)

# Load the consolidated results
metrics <- read.csv("../../results/tables/final_metrics.csv")

# Find the best Variant for each Dataset, Algorithm, Strategy based on ubaF
best_metrics <- metrics %>%
  group_by(Dataset, Algorithm, Strategy) %>%
  filter(ubaF == max(ubaF, na.rm = TRUE)) %>%
  slice(1) %>%
  ungroup()

# Create a pivot table for ubaF
# Rows = Dataset
# Columns = Strategy (for a given Algorithm)

algorithms <- unique(best_metrics$Algorithm)

for (algo in algorithms) {
  algo_data <- best_metrics %>% filter(Algorithm == algo)
  
  # Pivot
  pivot_table <- algo_data %>%
    select(Dataset, Strategy, ubaF) %>%
    pivot_wider(names_from = Strategy, values_from = ubaF)
  
  out_file <- sprintf("../../results/tables/summary_ubaF_%s.csv", algo)
  write.csv(pivot_table, file = out_file, row.names = FALSE)
  cat("Generated", out_file, "\n")
}
