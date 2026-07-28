library(dplyr)

metrics <- read.csv("../../results/tables/final_metrics.csv")

# LM Baseline (only 1 per dataset)
lm_base <- metrics %>% filter(Algorithm == "LM" & Strategy == "WFnone") %>% select(Dataset, Algorithm, ubaF_base = ubaF)
lm_comp <- metrics %>% filter(Algorithm == "LM" & Strategy != "WFnone") %>%
  inner_join(lm_base, by = c("Dataset", "Algorithm"))

# RF, SVM, NNET Baseline (have variants)
other_base <- metrics %>% filter(Algorithm != "LM" & Strategy == "WFnone") %>% select(Dataset, Algorithm, Variant, ubaF_base = ubaF)
other_comp <- metrics %>% filter(Algorithm != "LM" & Strategy != "WFnone") %>%
  inner_join(other_base, by = c("Dataset", "Algorithm", "Variant"))

comparisons <- bind_rows(lm_comp, other_comp) %>%
  mutate(
    Win = ifelse(!is.na(ubaF) & !is.na(ubaF_base) & ubaF > ubaF_base, 1, 0),
    Loss = ifelse(!is.na(ubaF) & !is.na(ubaF_base) & ubaF < ubaF_base, 1, 0)
  )

win_loss_summary <- comparisons %>%
  group_by(Algorithm, Strategy) %>%
  summarise(
    Wins = sum(Win),
    Losses = sum(Loss),
    Total_Tests = sum(!is.na(ubaF) & !is.na(ubaF_base)),
    WinRate = Wins / Total_Tests * 100,
    .groups = "drop"
  ) %>%
  arrange(Algorithm, Strategy)

print(win_loss_summary, n=100)
write.csv(win_loss_summary, file="../../results/tables/validation_win_loss.csv", row.names=FALSE)
