# 00_packages.R — Install and load required packages
# apep_1162: Belgium SSC Cut and Employment

pkgs <- c(
  "eurostat",      # Eurostat API
  "dplyr",         # Data manipulation
  "tidyr",         # Reshaping
  "ggplot2",       # Plotting (not used in V1, but for diagnostics)
  "fixest",        # Fixed effects estimation
  "modelsummary",  # Regression tables
  "kableExtra",    # Table formatting
  "jsonlite",      # JSON output for diagnostics
  "stringr",       # String manipulation
  "lubridate",     # Date handling
  "augsynth"       # Augmented synthetic control
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
