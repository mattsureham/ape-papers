# ============================================================================
# 00_packages.R — Package setup for apep_0902
# RTF Constitutional Amendments and Animal Production Employment
# ============================================================================

required_packages <- c(
  "duckdb",        # Azure Parquet access
  "arrow",         # Parquet I/O
  "dplyr",         # Data manipulation
  "tidyr",         # Reshaping
  "fixest",        # TWFE and Sun-Abraham
  "did",           # Callaway-Sant'Anna
  "ggplot2",       # (only for diagnostics, not final figures)
  "data.table",    # Fast data ops
  "jsonlite",      # diagnostics.json
  "stringr",       # String ops
  "fwildclusterboot", # Wild cluster bootstrap
  "modelsummary",  # Table output
  "kableExtra"     # Table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
