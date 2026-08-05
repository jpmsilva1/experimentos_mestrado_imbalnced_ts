rm(list=ls())
load("assets/datasets.rdata")
source("src/workflows.r")

library(tsensembler)

form <- target~.

nfolds <- 10
outer_split <- .7

ds <- ts_list[[1]]

cat("Running workflow...\n")
tryCatch({
  est <- workflow.get_estimations(
    ds = ds,
    form = form,
    nfolds = nfolds,
    outer_split = outer_split
  )
  print("Success!")
}, error = function(e) {
  print(e)
})
