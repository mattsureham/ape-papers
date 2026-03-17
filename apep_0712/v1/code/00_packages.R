# 00_packages.R — Install and load required packages
# apep_0712: UK Ground Rent Abolition

required_packages <- c(
  "tidyverse",    # data manipulation + ggplot2
  "data.table",   # fast CSV reading
  "fixest",       # high-dimensional FEs, clustering
  "rdrobust",     # RDD estimation (CCT bandwidth, local poly)
  "rddensity",    # McCrary density test
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "jsonlite",     # diagnostics output
  "lubridate"     # date handling
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
