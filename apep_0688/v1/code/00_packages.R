## 00_packages.R — Install and load required packages
pkgs <- c(
  "tidyverse", "fixest", "did", "data.table", "httr2", "jsonlite",
  "readxl", "writexl", "kableExtra", "modelsummary", "xtable",
  "sf"
)
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
}
invisible(lapply(pkgs, library, character.only = TRUE))

cat("All packages loaded.\n")
