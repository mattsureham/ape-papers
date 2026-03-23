## 00_packages.R — Load and install required packages
## apep_0796: Swiss Second Home Ban RDD

pkgs <- c(
  "readxl", "httr", "jsonlite", "dplyr", "tidyr", "purrr",
  "rdrobust", "rddensity", "fixest", "modelsummary",
  "xtable", "data.table"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
