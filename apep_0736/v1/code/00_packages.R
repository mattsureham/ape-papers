## 00_packages.R — Load required packages
## apep_0736: Who Counts the Dead?

pkgs <- c(
  "tidyverse", "fixest", "data.table", "jsonlite",
  "httr", "readr", "sf", "xtable", "modelsummary",
  "lmtest", "sandwich", "boot"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
