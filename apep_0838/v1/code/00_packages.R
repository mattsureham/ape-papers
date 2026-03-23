# 00_packages.R — Install and load required packages
pkgs <- c(
  "data.table", "fixest", "ggplot2", "httr", "jsonlite",
  "readr", "stringr", "kableExtra", "modelsummary", "sandwich"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
