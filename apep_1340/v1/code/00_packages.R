# 00_packages.R — Load required packages for apep_1340
# MSA Redefinitions and CRA Mortgage Lending

required <- c(
  "tidyverse",    # Data manipulation
  "fixest",       # Fast fixed effects
  "data.table",   # Memory-efficient I/O
  "httr",         # API calls
  "jsonlite",     # JSON parsing
  "rdrobust",     # RDD estimation
  "did",          # Callaway-Sant'Anna DiD
  "modelsummary", # Regression tables
  "kableExtra"    # Table formatting
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
