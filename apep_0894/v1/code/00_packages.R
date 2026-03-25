# =============================================================================
# 00_packages.R — Load required packages
# apep_0894: CFPB Payday Lending Rule and Credit-Sector Labor Markets
# =============================================================================

required_packages <- c(
  "tidyverse",     # Data manipulation + ggplot2

"data.table",    # Fast data ops
  "fixest",        # Fast fixed effects (feols, event study)
  "did",           # Callaway-Sant'Anna DiD
  "duckdb",        # Azure Parquet access
  "DBI",           # Database interface
  "jsonlite",      # diagnostics.json output
  "xtable",        # LaTeX table generation
  "sandwich",      # Robust SEs
  "lmtest"         # Coefficient tests
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
