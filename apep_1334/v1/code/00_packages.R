##############################################################################
# 00_packages.R — Load required packages
# Paper: "Paper Patents and Real Markets" (apep_1334)
##############################################################################

pkgs <- c(
  "arrow",        # Read parquet files
  "data.table",   # Fast data manipulation
  "fixest",       # IV/2SLS with high-dimensional FE
  "modelsummary", # Regression tables
  "kableExtra",   # Table formatting
  "sandwich",     # Robust SE
  "jsonlite"      # Write diagnostics
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
