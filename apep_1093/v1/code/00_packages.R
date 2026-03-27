# 00_packages.R — Load required packages for apep_1093
# Pay Transparency Laws and the Racial New-Hire Earnings Gap

required <- c(
  "tidyverse",    # data manipulation + ggplot2
  "fixest",       # fast fixed effects (feols)
  "did",          # Callaway-Sant'Anna estimator
  "data.table",   # memory-efficient data ops
  "duckdb",       # Azure/Parquet access
  "DBI",          # database interface
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "jsonlite",     # diagnostics.json output
  "sandwich",     # robust SEs
  "fwildclusterboot" # wild cluster bootstrap
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
