# 00_packages.R — Load required packages
# apep_0967: CSE Reform and Far-Right Voting in France

required_packages <- c(
  "tidyverse",    # data manipulation + ggplot2

"fixest",       # fast fixed effects estimation
  "arrow",        # read Parquet files efficiently
  "readxl",       # read XLS election data (2017)
  "modelsummary", # regression tables
  "sandwich",     # robust SEs
  "lmtest",       # coeftest
  "jsonlite",     # diagnostics.json output
  "kableExtra"    # table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
