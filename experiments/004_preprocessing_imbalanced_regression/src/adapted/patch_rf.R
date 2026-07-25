lines <- readLines("expsIS_RF.R")

# Add doParallel library at the top
idx <- grep("library\\(performanceEstimation\\)", lines)[1]
lines <- append(lines, c("library(doParallel)", "registerDoParallel(cores=7)"), after=idx)

# Change load path
lines <- gsub("load\\(\"DataSets15.Rdata\"\\)", "load(\"../original/repo/Data/DataSets15.Rdata\")", lines)

# Change save path to results/RF/
lines <- gsub("save\\(list=resObj,file=paste\\(", "save(list=resObj,file=paste('results/RF/',", lines)

# Change outer for loop to foreach
# First, find "for(d in seq_along(myDSs)) {"
idx_for <- grep("for\\(d in seq_along\\(myDSs\\)\\) \\{", lines)[1]
lines[idx_for] <- "foreach(d = seq_along(myDSs), .packages = c('performanceEstimation', 'UBL', 'uba', 'e1071', 'randomForest', 'earth', 'nnet')) %dopar% {"

# Save
writeLines(lines, "expsIS_RF.R")
