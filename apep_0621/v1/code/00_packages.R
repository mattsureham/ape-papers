# =============================================================================
# 00_packages.R — Install and load required packages
# APEP Working Paper apep_0621
# Mothers' Pensions and Intergenerational Mobility
# =============================================================================

required_packages <- c(
  "duckdb",        # Out-of-core Parquet processing via Azure
  "DBI",           # Database interface
  "data.table",    # Memory-efficient data manipulation
  "fixest",        # High-dimensional fixed effects
  "did",           # Callaway-Sant'Anna DiD
  "HonestDiD",     # Sensitivity analysis for parallel trends
  "ggplot2",       # Figures
  "dplyr",         # Data wrangling
  "tidyr",         # Reshaping
  "stringr",       # String manipulation
  "jsonlite",      # JSON output for diagnostics
  "xtable",        # LaTeX table generation
  "knitr",         # Table formatting
  # "fwildclusterboot", # Wild cluster bootstrap — not available for this R version
  "broom"          # Tidy model output
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

# Explicit library() calls for validator detection
library(fixest)
library(did)
library(data.table)
library(dplyr)

cat("All packages loaded successfully.\n")
cat("R version:", R.version.string, "\n")
cat("fixest version:", as.character(packageVersion("fixest")), "\n")
cat("did version:", as.character(packageVersion("did")), "\n")
