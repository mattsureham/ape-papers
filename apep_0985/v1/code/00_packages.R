# 00_packages.R — Install and load required packages
# apep_0985: Catalytic Converter Anti-Theft Laws

pkgs <- c(
  "tidyverse", "data.table", "fixest", "did",
  "quantmod", "jsonlite", "httr",
  "sandwich", "lmtest", "modelsummary",
  "kableExtra", "HonestDiD"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
