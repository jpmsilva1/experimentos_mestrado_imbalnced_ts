#!/usr/bin/env Rscript

# 1. Install standard CRAN dependencies
required_cran <- c("assertthat", "dplyr", "foreach", "lubridate", "stringr", "devtools", "earth", "ranger", "rpart", "doParallel", "gdata", "Hmisc", "operators", "fields", "ROCR")
to_install_cran <- required_cran[!(required_cran %in% installed.packages()[,"Package"])]
if (length(to_install_cran) > 0) {
  cat("Installing CRAN packages: ", paste(to_install_cran, collapse=", "), "\n")
  install.packages(to_install_cran, repos="http://cran.us.r-project.org")
}

# 2. Install spatial dependencies (sf, lwgeom)
spatial_pkgs <- c("sf", "lwgeom")
to_install_spatial <- spatial_pkgs[!(spatial_pkgs %in% installed.packages()[,"Package"])]
if (length(to_install_spatial) > 0) {
  cat("Installing spatial packages: ", paste(to_install_spatial, collapse=", "), "\n")
  install.packages(to_install_spatial, repos="http://cran.us.r-project.org")
}

# 3. Install DMwR, DMwR2 and UBL from GitHub
if (!("DMwR" %in% installed.packages()[,"Package"])) {
  cat("Installing DMwR from cran/DMwR github mirror...\n")
  devtools::install_github("cran/DMwR")
}
if (!("DMwR2" %in% installed.packages()[,"Package"])) {
  cat("Installing DMwR2 from cran/DMwR2 github mirror...\n")
  devtools::install_github("cran/DMwR2")
}
if (!("UBL" %in% installed.packages()[,"Package"])) {
  cat("Installing UBL from cran/UBL github mirror...\n")
  devtools::install_github("cran/UBL")
}

# 4. Install uba from our local scratch folder
if (!("uba" %in% installed.packages()[,"Package"])) {
  cat("Installing local patched 'uba' package...\n")
  install.packages("../scratch/uba", repos = NULL, type = "source")
}

# 5. Install the STResamplingDSAA package
cat("Installing local STResamplingDSAA package...\n")
install.packages("original", repos = NULL, type = "source")

cat("Installation complete.\n")
