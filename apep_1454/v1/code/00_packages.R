# 00_packages.R — Install and load required packages
pkgs <- c("httr", "jsonlite", "dplyr", "tidyr", "fixest", "rdrobust",
          "ggplot2", "modelsummary", "kableExtra", "stringr", "purrr")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
