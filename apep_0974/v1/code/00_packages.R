# 00_packages.R — Package management for apep_0974
pkgs <- c("tidyverse", "fixest", "did", "arrow", "data.table", "jsonlite",
          "modelsummary", "kableExtra", "sandwich", "lmtest")

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
