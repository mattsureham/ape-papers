# 00_packages.R — Install/load required packages
pkgs <- c("tidyverse", "fixest", "did", "duckdb", "DBI", "data.table",
          "xtable", "jsonlite", "modelsummary", "kableExtra")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}
cat("All packages loaded.\n")
