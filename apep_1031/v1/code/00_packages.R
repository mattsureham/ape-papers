# =============================================================================
# 00_packages.R — Load required packages
# apep_1031: Kitchen Table Capitalism
# =============================================================================

required_packages <- c(
  "tidyverse",    # data wrangling + ggplot2
  "fixest",       # fixed effects estimation
  "did",          # Callaway-Sant'Anna DiD
  "duckdb",       # Azure Parquet access
  "data.table",   # fast data manipulation
  "jsonlite",     # diagnostics output
  "kableExtra",   # table formatting
  "fwildclusterboot"  # wild cluster bootstrap
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
