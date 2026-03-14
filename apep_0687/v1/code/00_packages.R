## 00_packages.R — Load and install required packages
## Paper: apep_0687 — Nutrient Neutrality and Housing Supply

pkgs <- c(
  "tidyverse", "fixest", "did", "HonestDiD",
  "data.table", "readxl", "readODS", "httr2", "jsonlite",
  "modelsummary", "kableExtra", "xtable"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
