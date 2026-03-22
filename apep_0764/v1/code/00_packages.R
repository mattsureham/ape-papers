# 00_packages.R — Install and load required packages
# apep_0764: Brazil Intermittent Contracts

## Required packages: fixest, data.table, bigrquery
pkgs <- c(
  "bigrquery",    # BigQuery access
  "data.table",   # Fast data manipulation
  "fixest",       # Fast fixed effects estimation
  "ggplot2",      # Plotting
  "httr",         # API calls (SIDRA)
  "jsonlite",     # JSON parsing
  "xtable",       # LaTeX tables
  "sandwich",     # Robust SEs
  "lmtest",       # Coefficient testing
  "scales",       # Formatting
  "modelsummary"  # Regression tables
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
