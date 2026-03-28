## 00_packages.R — Install and load required packages
## apep_0749 v2: The Game-Day Externality

pkgs <- c(
  "data.table", "fixest", "did",        # Core econometrics
  "httr", "jsonlite", "readr",          # Data fetching
  "xtable", "kableExtra",              # Tables
  "lubridate", "stringr",              # Date/string handling
  "sandwich", "lmtest",                # Robust inference
  "ggplot2", "patchwork", "scales",    # Figures (V2)
  "rvest",                             # NFL schedule scraping (V2)
  "MASS",                              # Negative binomial (V2)
  "modelsummary"                       # Table generation (V2)
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  suppressPackageStartupMessages(library(p, character.only = TRUE))
}

options(modelsummary_factory_default = "kableExtra")
setFixest_nthreads(parallel::detectCores())

cat("All packages loaded.\n")
