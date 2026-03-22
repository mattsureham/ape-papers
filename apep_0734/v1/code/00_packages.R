# 00_packages.R — Install and load required packages
# apep_0734: Wales 20mph Speed Limit and Road Casualties

pkgs <- c(
  "data.table", "fixest", "ggplot2", "dplyr", "tidyr", "readr",
  "jsonlite", "stringr", "lubridate", "knitr",
  "xtable", "httr", "sandwich"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded successfully.\n")
