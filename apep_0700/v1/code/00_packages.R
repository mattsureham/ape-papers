## 00_packages.R — Install and load required packages for apep_0700
## UK LHA Freeze and Homelessness

required_pkgs <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects estimation (feols)
  "did",           # Callaway-Sant'Anna (if needed)
  "modelsummary",  # Regression tables
  "kableExtra",    # Table formatting
  "readxl",        # Read Excel/ODS files
  "httr2",         # HTTP requests
  "jsonlite",      # JSON parsing
  "readr",         # CSV reading
  "stringr",       # String operations
  "lubridate"      # Date handling
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
