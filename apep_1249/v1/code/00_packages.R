## 00_packages.R — Install/load required packages for apep_1249
pkgs <- c(
  "data.table", "fixest", "ggplot2", "httr", "jsonlite",
  "sandwich", "lmtest", "modelsummary",
  "kableExtra", "xtable", "readr", "stringr", "dplyr", "tidyr"
)
for (p in pkgs) {
  if (!requireNamespace(p, quietly = TRUE)) install.packages(p, repos = "https://cloud.r-project.org")
  library(p, character.only = TRUE)
}
cat("All packages loaded.\n")
