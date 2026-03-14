## ============================================================
## 00_packages.R — Load and install required packages
## apep_0674: PBF and the Cream-Skimming Margin
## ============================================================

required_packages <- c(
  "tidyverse",    # data wrangling + ggplot2

"fixest",       # fast TWFE, Sun-Abraham
  "did",          # Callaway-Sant'Anna
  "duckdb",       # read IPEDS DuckDB
  "DBI",          # database interface
  "modelsummary", # regression tables
  "kableExtra",   # table formatting
  "xtable",       # LaTeX tables
  "jsonlite",     # diagnostics output
  "sandwich",     # robust SEs
  "lmtest",       # coefficient tests
  "HonestDiD"     # sensitivity bounds
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

cat("All packages loaded successfully.\n")
