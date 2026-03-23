# 00_packages.R — Load and install required packages
pkgs <- c("eurostat", "dplyr", "tidyr", "fixest", "ggplot2",
          "modelsummary", "kableExtra", "jsonlite", "purrr", "stringr",
          "fwildclusterboot")
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}
cat("All packages loaded.\n")
