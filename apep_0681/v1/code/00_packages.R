# 00_packages.R — Install and load required packages
# apep_0681: IR35 Off-Payroll Reforms

pkgs <- c(
  "httr2",       # HTTP requests
  "jsonlite",    # JSON parsing
  "dplyr",       # data manipulation
  "tidyr",       # reshaping
  "readr",       # CSV I/O
  "ggplot2",     # plotting
  "fixest",      # TWFE regressions
  "modelsummary",# regression tables
  "kableExtra",  # table formatting
  "data.table",  # fast data ops
  "stringr"      # string manipulation
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  suppressPackageStartupMessages(library(p, character.only = TRUE))
}

cat("All packages loaded.\n")
