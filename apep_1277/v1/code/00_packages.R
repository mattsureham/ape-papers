# 00_packages.R — Load required packages
# Minimum Wages and the Racial Hiring Gap (apep_1277)

required_pkgs <- c("tidyverse", "data.table", "fixest", "did", "duckdb", "jsonlite")
for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
