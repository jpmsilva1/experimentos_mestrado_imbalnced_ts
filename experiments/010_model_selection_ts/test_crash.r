source("src/adapted/src/workflows.r")
library(tsensembler)
load("assets/datasets.rdata")
ds <- ts_list[[1]] # Try just dataset 1
form <- target~.
nfolds <- 10
outer_split <- .7
source("src/adapted/src/model-specs.r")

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
