# 00_packages.R — Package dependencies for apep_0909
# PCC Electoral Cycles and Crime Investigation Quality

required_packages <- c(
  "data.table",    # Fast data manipulation
  "fixest",        # Fixed effects estimation (feols)
  "readxl",        # Read Excel files
  "readODS",       # Read ODS files
  "httr",          # HTTP requests for data download
  "jsonlite",      # JSON parsing
  "sandwich",      # Robust standard errors
  "lmtest",        # Coefficient testing
  "fwildclusterboot", # Wild cluster bootstrap
  "modelsummary",  # Table output
  "kableExtra",    # LaTeX table formatting
  "ggplot2"        # Not used for V1 figures, but needed for diagnostics
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
