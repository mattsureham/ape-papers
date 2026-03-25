## 00_packages.R — Load required packages
## apep_0905: Argentina Aviation Deregulation

pkgs <- c(
  "data.table", "fixest", "ggplot2", "dplyr", "tidyr", "readr",
  "lubridate", "stringr", "jsonlite", "knitr", "kableExtra",
  "did", "sandwich", "lmtest", "broom"
)

for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}

cat("All packages loaded.\n")
