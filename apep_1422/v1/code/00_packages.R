# 00_packages.R — Install and load required packages
# apep_1422: When Bugs Hatch Early

required_packages <- c(
  "tidyverse",    # data manipulation + ggplot2
  "fixest",       # fast fixed effects estimation
  "data.table",   # fast data operations
  "sf",           # spatial joins (county assignment)
  "jsonlite"      # diagnostics.json
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
