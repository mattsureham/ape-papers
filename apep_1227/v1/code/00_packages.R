# =============================================================================
# 00_packages.R — Load required packages for apep_1227
# Occupational licensing deregulation and Hispanic earnings
# =============================================================================

required_packages <- c(
  "duckdb", "DBI", "arrow",       # Azure data access
  "data.table", "dplyr", "tidyr", # Data manipulation
  "fixest",                        # TWFE + Sun-Abraham
  "did",                           # Callaway-Sant'Anna
  "ggplot2",                       # Plotting (event studies)
  "modelsummary",                  # Table generation
  "sandwich", "lmtest",           # Robust inference
  "fwildclusterboot",             # Wild cluster bootstrap
  "jsonlite",                      # diagnostics.json
  "kableExtra"                     # LaTeX tables
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
