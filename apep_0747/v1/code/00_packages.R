## 00_packages.R — Load and install required packages
pkgs <- c(
  "tidyverse", "data.table", "fixest", "did",
  "tidycensus", "httr", "jsonlite",
  "xtable", "modelsummary"
)
# fwildclusterboot not available for this R version; use boottest from fixest instead
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}
cat("All packages loaded.\n")
