## 00_packages.R — Load required packages
## APEP apep_1337: Section 301 Tariffs and the Asian-White Wage Gap

pkgs <- c(
  "DBI", "duckdb",       # Azure data access
  "dplyr", "tidyr",       # data manipulation
  "data.table",           # fast merges
  "fixest",               # TWFE / Sun-Abraham
  "modelsummary",         # table output
  "jsonlite",             # diagnostics output
  "httr",                 # API calls
  "ggplot2"               # figures (not used in V1 but for diagnostics)
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  suppressPackageStartupMessages(library(p, character.only = TRUE))
}

cat("All packages loaded.\n")

## Set working directory to code/ if not already there
if (!grepl("/code/?$", getwd())) {
  script_dir <- getSrcDirectory(function() {})
  if (nchar(script_dir) > 0) setwd(script_dir)
}
