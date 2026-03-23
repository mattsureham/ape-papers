## 00_packages.R — Install and load required packages
## apep_0840: Competing News IV and Swiss Referendum Turnout

required_packages <- c(
  "swissdd",        # Swiss referendum data
  "bigrquery",      # Google BigQuery for GDELT
  "data.table",     # Fast data manipulation
  "fixest",         # Fixed effects IV estimation
  "modelsummary",   # Regression tables
  "jsonlite",       # JSON I/O
  "kableExtra",     # Table formatting
  "xtable",         # LaTeX tables
  "sandwich",       # Robust SEs
  "lmtest"          # Coefficient tests
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
