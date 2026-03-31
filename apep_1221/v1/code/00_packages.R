## =============================================================================
## 00_packages.R — Install and load required packages
## Paper: Rejected and Relocated (apep_1221)
## =============================================================================

pkgs <- c(
  "bigrquery", "DBI",         # BigQuery access
  "data.table",               # Fast data manipulation
  "fixest",                   # IV/2SLS with high-dimensional FE
  "modelsummary",             # Regression tables
  "kableExtra",               # Table formatting
  "jsonlite",                 # JSON for diagnostics
  "xtable"                    # LaTeX table output
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
