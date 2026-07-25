# Install uba from GitHub instead of the broken tar.gz link
if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes", repos="https://cloud.r-project.org/")
}
remotes::install_github("rpribeiro/uba")
print("uba installed successfully.")
