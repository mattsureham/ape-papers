## 00_packages.R — Install and load required packages
pkgs <- c(
  "WDI",           # World Bank Development Indicators
  "httr", "jsonlite",  # API calls
  "dplyr", "tidyr", "readr", "stringr", "purrr",
  "fixest",        # Fast fixed effects estimation
  "modelsummary",  # Regression tables
  # "fwildclusterboot",  # Wild cluster bootstrap — not available for this R version
  "kableExtra",    # Table formatting
  "ggplot2"        # Not used for figures in V1, but for diagnostics
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
