rm(list=ls())
load("assets/datasets.rdata")
source("src/workflows.r")
library(tsensembler)

form <- target~.
nfolds <- 10
outer_split <- .7

ds <- ts_list[[10]]
cat("Testing dataset 10...\n")

est <- workflow.get_estimations(
  ds = ds,
  form = form,
  nfolds = nfolds,
  outer_split = outer_split
)
print("Success for 10!")
