# 00_packages.R — Package loading for apep_1026
# Marijuana legalization and FHA mortgage exclusion

required <- c(
  "data.table", "fixest", "did",        # Core DiD estimation
  "ggplot2", "modelsummary",             # Tables
  "httr", "jsonlite",                    # API access
  "dplyr", "tidyr", "readr", "stringr",  # Data wrangling
  "purrr", "glue"                        # Functional + string
)

for (pkg in required) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
