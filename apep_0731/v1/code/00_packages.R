## 00_packages.R — Load required libraries
## apep_0731: Nonprofit bunching at state audit thresholds

required_pkgs <- c(
  "data.table", "fixest", "ggplot2", "dplyr", "tidyr", "readr",
  "stringr", "jsonlite", "xtable", "knitr", "httr",
  "scales", "broom"
)

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
  library(pkg, character.only = TRUE)
}

cat("All packages loaded.\n")
