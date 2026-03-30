##############################################################################
# 00_packages.R — Install and load required packages
# apep_1168: Contagious NIMBYism
##############################################################################

pkgs <- c(
  "data.table", "arrow", "duckdb", "DBI",
  "fixest", "did",             # Econometrics
  "ggplot2", "scales",         # Plotting
  "tidycensus", "httr", "jsonlite", "readr", "readxl",
  "sf", "tigris",             # Spatial
  "stringr", "lubridate",
  "modelsummary", "kableExtra", "xtable"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org", quiet = TRUE)
  }
  suppressPackageStartupMessages(library(p, character.only = TRUE))
}

cat("All packages loaded.\n")
