# 00_packages.R — apep_0856: Tipped MW Stability Paradox
# Install and load required packages

pkgs <- c(
  "duckdb", "DBI", "arrow",           # Azure data access
  "data.table", "dplyr", "tidyr",     # Data manipulation
  "fixest",                            # TWFE, event study
  "did",                               # Callaway-Sant'Anna
  "ggplot2",                           # Figures (for diagnostics)
  "modelsummary",                      # Tables
  "kableExtra",                        # LaTeX table formatting
  "jsonlite",                          # Diagnostics output
  "fredr",                             # FRED API
  "sandwich", "lmtest"                 # Robust SEs
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cran.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
