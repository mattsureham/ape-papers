# 00_packages.R — Install and load required packages
# APEP-1200: Swiss Mass Immigration Initiative Close-Vote RDD

required_packages <- c(
  "tidyverse",    # Data manipulation
  "fixest",       # Fixed effects estimation
  "rdrobust",     # RDD estimation (Cattaneo et al.)
  "rddensity",    # McCrary manipulation test
  "httr",         # API calls
  "jsonlite",     # JSON parsing
  "data.table",   # Memory-efficient operations
  "sandwich",     # Robust standard errors
  "lmtest"        # Coefficient tests
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# Install swissdd from GitHub (removed from CRAN 2022)
if (!requireNamespace("swissdd", quietly = TRUE)) {
  if (!requireNamespace("remotes", quietly = TRUE)) {
    install.packages("remotes", repos = "https://cloud.r-project.org")
  }
  remotes::install_github("zumbov2/swissdd")
}
library(swissdd)

cat("All packages loaded successfully.\n")
cat("R version:", R.version.string, "\n")
cat("rdrobust version:", packageVersion("rdrobust") |> as.character(), "\n")
