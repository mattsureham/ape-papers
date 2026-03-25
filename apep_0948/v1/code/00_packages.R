# 00_packages.R — Load all required packages
# Paper: The Fiscal Shadow of the Pill Mill (apep_0948)

required_packages <- c(
  "arrow",        # Parquet file I/O
  "dplyr",        # Data manipulation
  "tidyr",        # Reshaping
  "readr",        # CSV reading
  "stringr",      # String operations
  "fixest",       # IV/2SLS estimation with feols
  "ivreg",        # Classical IV diagnostics
  "sandwich",     # HC robust standard errors
  "lmtest",       # Coefficient testing
  "xtable",       # LaTeX table generation
  "jsonlite",     # JSON I/O for diagnostics
  "httr",         # API calls (Census, WONDER)
  "glue"          # String interpolation
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
