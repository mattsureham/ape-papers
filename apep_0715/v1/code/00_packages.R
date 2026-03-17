## 00_packages.R — Install and load required packages
## apep_0715: FOBT Stake Reduction

required_packages <- c(
  "readxl",       # Excel file reading
  "httr",         # HTTP downloads
  "dplyr",        # Data manipulation
  "tidyr",        # Reshaping
  "stringr",      # String operations
  "lubridate",    # Date handling
  "fixest",       # Fast fixed effects estimation
  "modelsummary", # Table formatting
  "ggplot2",      # Plotting (for diagnostics only, not in paper)
  "jsonlite",     # JSON output
  "kableExtra",   # Table formatting
  "readr",        # CSV reading
  "purrr",        # Functional programming
  "broom"         # Model tidying
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
