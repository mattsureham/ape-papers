# 00_packages.R — Package installation and loading for apep_1426
# TV News Amplification and Workplace Safety Deterrence

required_packages <- c(
  "data.table",      # Fast data manipulation
  "fixest",          # Fast fixed-effects IV estimation
  "httr",            # API calls
  "jsonlite",        # JSON parsing
  "stringr",         # String operations for keyword matching
  "lubridate",       # Date handling
  "bigrquery",       # BigQuery access for GDELT
  "sandwich",        # Robust standard errors
  "lmtest",          # Coefficient testing
  "xtable",          # LaTeX table output
  "modelsummary",    # Regression tables
  "kableExtra"       # Table formatting
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
