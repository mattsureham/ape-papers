## 00_packages.R — Install and load required packages
## apep_0863: The Forecaster Lottery

pkgs <- c(
  "data.table", "fixest", "sf", "jsonlite", "httr",
  "sandwich", "lmtest", "spdep", "modelsummary",
  "kableExtra", "xtable"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
