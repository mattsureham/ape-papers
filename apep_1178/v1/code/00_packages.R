# ==============================================================================
# 00_packages.R — CRNA Supervision Opt-Out and Ambulatory Labor Markets
# ==============================================================================

required_packages <- c(
  "duckdb",       # Azure Parquet access
  "dplyr",        # Data manipulation
  "tidyr",        # Reshaping
  "fixest",       # TWFE, Sun-Abraham
  "did",          # Callaway-Sant'Anna
  "ggplot2",      # Plotting (for diagnostics only)
  "data.table",   # Fast data ops
  "jsonlite",     # diagnostics.json output
  "xtable",       # LaTeX table generation
  "HonestDiD"     # Sensitivity analysis for PT violations
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
