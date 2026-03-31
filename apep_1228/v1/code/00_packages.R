## 00_packages.R — Load required packages for apep_1228
## GIPP waterbed effect in UK insurance

required_packages <- c(
  "readxl",       # Read FCA XLSX data
  "data.table",   # Fast data manipulation
  "fixest",       # Fixed effects estimation (feols)
  "ggplot2",      # (unused in V1 — no figures)
  "dplyr",        # Data wrangling
  "tidyr",        # Reshaping
  "stringr",      # String manipulation
  "httr",         # HTTP downloads
  "jsonlite",     # JSON output for diagnostics
  "knitr",        # Table formatting
  "xtable",       # LaTeX table generation
  "modelsummary"  # Regression table output
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
