# =============================================================================
# 00_packages.R — APEP Working Paper apep_1330
# HEERF Windfall and Institutional Absorption
# =============================================================================

required_packages <- c(
  "duckdb", "DBI",          # Azure DuckDB access
  "data.table", "dplyr",    # Data manipulation
  "fixest",                 # IV/2SLS with fixed effects
  "modelsummary",           # Table output
  "xtable",                 # LaTeX tables
  "jsonlite",               # diagnostics.json
  "sandwich", "lmtest"      # Robust inference
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
