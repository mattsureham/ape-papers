## 00_packages.R — Install and load required packages
## apep_0749: The Game-Day Externality

pkgs <- c(
  "data.table", "fixest", "did",        # Core econometrics
  "httr", "jsonlite", "readr",          # Data fetching
  "xtable", "kableExtra",              # Tables
  "lubridate", "stringr",              # Date/string handling
  "sandwich", "lmtest",                # Robust inference
  "HonestDiD"                          # Sensitivity analysis
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
