for(file in c("expsIS_SVM.R", "expsIS_NNET.R")) {
  lines <- readLines(file)
  
  idx <- grep("library\\(performanceEstimation\\)", lines)[1]
  lines <- append(lines, c("library(doParallel)", "registerDoParallel(cores=7)"), after=idx)
  
  lines <- gsub("load\\(\"DataSets15.Rdata\"\\)", "load(\"../original/repo/Data/DataSets15.Rdata\")", lines)
  
  if (file == "expsIS_SVM.R") {
    lines <- gsub("save\\(list=resObj,file=paste\\(", "save(list=resObj,file=paste('results/SVM/',", lines)
  } else {
    lines <- gsub("save\\(list=resObj,file=paste\\(", "save(list=resObj,file=paste('results/NNET/',", lines)
  }
  
  idx_for <- grep("for\\(d in seq_along\\(myDSs\\)\\) \\{", lines)[1]
  lines[idx_for] <- "foreach(d = seq_along(myDSs), .packages = c('performanceEstimation', 'UBL', 'uba', 'e1071', 'randomForest', 'earth', 'nnet')) %dopar% {"
  
  writeLines(lines, file)
}
