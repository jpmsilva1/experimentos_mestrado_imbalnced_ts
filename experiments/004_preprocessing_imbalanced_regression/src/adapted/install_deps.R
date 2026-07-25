# Dependency installation script for exp004

# 1. Install standard CRAN packages
install.packages(c("performanceEstimation", "UBL", "e1071", "randomForest", "earth", "nnet", "ggplot2", "scmamp"), repos="https://cloud.r-project.org/")

# 2. Install DMwR from archive (deprecated from CRAN)
if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes", repos="https://cloud.r-project.org/")
}
remotes::install_version("DMwR", version="0.4.1", repos="https://cloud.r-project.org/")

# 3. Install uba from external URL
install.packages("http://www.dcc.fc.up.pt/~rpribeiro/uba/uba_0.7.7.tar.gz", repos=NULL, type="source")

print("Installation complete.")
